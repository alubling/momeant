class Story < ActiveRecord::Base
  acts_as_taggable
  
  belongs_to :user
  has_and_belongs_to_many :topics
  has_many :purchases
  has_many :bookmarks
  has_many :users_who_bookmarked, :through => :bookmarks, :source => :user
  has_many :recommendations
  has_many :users_who_recommended, :through => :recommendations, :source => :user
  
  has_many :pages, :order => "number ASC", :dependent => :destroy
    
  validates :title, :presence => true, :length => (2..256), :unless => :autosaving
  validates :excerpt, :length => (2..1024), :unless => :autosaving
  validates :price, :format => /[0-9.,]+/, :unless => :autosaving
  
  validate  :at_least_one_page
  
  scope :published, where(:published => true)
  
  attr_accessor :autosaving
  
  def at_least_one_page
    if !self.autosaving && self.pages.count == 0
      self.errors.add(:base, "Your story needs at least one page")
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
    !user.nil? && self.user == user
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