class Story < ActiveRecord::Base
  acts_as_taggable
  
  searchable do
    text :title, :boost => 2.0
    text(:author_name) { user.name }
    text :synopsis
    text :topics do
      topics.map { |topic| topic.name }
    end
    text :pages do
      pages.inject("") { |x,n| x << "#{n.text} " }
    end
    boolean :published
  end
  
  belongs_to :user
  has_and_belongs_to_many :topics
  
  has_many :curations
  has_many :bookmarks, :dependent => :destroy
  has_many :users_who_bookmarked, :through => :bookmarks, :source => :user
  has_many :rewards, :dependent => :destroy
  has_many :users_who_rewarded, :through => :rewards, :source => :user
  has_many :comments, :dependent => :destroy
  
  has_many :pages, :order => "number ASC", :dependent => :destroy
    
  validates :title, :presence => true, :length => (2..256), :unless => :autosaving
  validates :synopsis, :length => (2..1024), :unless => :autosaving
  
  validate  :at_least_one_page, :unless => :autosaving
  
  scope :published, where(:published => true)
  scope :newest_first, order("created_at DESC")
  scope :popular, where("likes_count > 0").order("likes_count DESC")
  
  attr_accessor :autosaving
  
  def to_param
    if title.blank?
      "#{id}"
    else
      "#{id}-#{title.gsub(/[^a-zA-Zd]/, '-')}"
    end
  end
  
  def at_least_one_page
    if self.pages.count == 0
      self.errors.add(:base, "Your story must have at least one page")
      return false
    end
  end
  
  def free?
    self.price == 0
  end
  
  def draft?
    !self.published
  end
  
  def topic_list
    self.topics.map{|t| t.name}.join(', ')
  end
  
  def owner?(user)
    user.present? && self.user == user
  end
  
  def liked_by?(user)
    user.present? && self.users_who_liked.include?(user)
  end
  
  def recommended_by?(user)
    user.present? && self.users_who_recommended.include?(user)
  end
  
  def thumbnail
    thumbnail = self.thumbnail_page || 1
    page_index = thumbnail - 1
    if self.pages[page_index]
      return self.pages[page_index]
    else
      return self.pages.first
    end
  end
  
  def page_at(number)
    return self.pages.find_by_number(number)
  end
  
  def similar_stories
    # find other stories by my creator
    stories = self.user.created_stories
    
    # find other stories with matching topics
    my_topic_ids = self.topics.map { |topic| topic.id }.join(",")
    stories += Story.joins(:topics).where("topics.id IN (#{my_topic_ids})") unless my_topic_ids.blank?
    
    # remove duplicates and this story
    stories.uniq - [self]
  end
end