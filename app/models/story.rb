class Story < ActiveRecord::Base
  acts_as_taggable
  
  searchable do
    text :title, :boost => 2.0
    text(:author_name) { user.name }
    text :synopsis
    text :tags do
      tags.map { |tag| tag.name }
    end
    text :pages do
      pages.inject("") { |x,n| x << "#{n.text} " }
    end
    boolean :published
  end
  
  has_attached_file :thumbnail,
    :styles => { :large => "630x420#", :medium => "288x180#", :small => "150x100#", :petite => "95x60#" },
    :path          => "story_thumbnails/:id/:style.:extension",
    :storage        => :s3,
    :s3_credentials => {
      :access_key_id       => ENV['S3_KEY'],
      :secret_access_key   => ENV['S3_SECRET']
    },
    :bucket        => ENV['S3_BUCKET']
  
  belongs_to :user
  belongs_to :gallery
  has_and_belongs_to_many :topics
  
  has_many :curations, :dependent => :destroy

  has_many :bookmarks, :dependent => :destroy
  has_many :users_who_bookmarked, :through => :bookmarks, :source => :user

  has_many :rewards
  has_many :users_who_rewarded, :through => :rewards, :source => :user

  has_many :views, :dependent => :destroy
  has_many :users_who_viewed, :through => :views, :source => :user

  has_many :comments, :dependent => :destroy
  
  has_many :pages, :order => "number ASC", :dependent => :destroy
    
  validates :title, :presence => true, :length => (2..256), :unless => :autosaving
  validates :synopsis, :length => (2..1024), :unless => :autosaving
  validates_attachment_presence :thumbnail, :unless => :autosaving, :message => "must be chosen"
  
  validate  :at_least_one_page, :unless => :autosaving
  
  scope :published, where(:published => true)
  scope :newest_first, order("created_at DESC")
  scope :most_rewarded, where("reward_count > 0").order("reward_count DESC")
  scope :no_gallery, where(:gallery_id => nil)
  
  attr_accessor :autosaving
    
  def to_param
    if title.blank?
      "#{id}"
    else
      "#{id}-#{title.gsub(/[^a-zA-Zd0-9]/, '-')}"
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
  
  def page_at(number)
    return self.pages.find_by_number(number)
  end
  
  def external_text_or_http
    if self.is_external? && self.pages.first.present? && self.pages.first.is_a?(ExternalPage)
      "http://#{self.pages.first.text}"
    else
      "http://"
    end
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
  
  def similar_stories_different_creator
    # find other stories with matching topics
    my_topic_ids = self.topics.map { |topic| topic.id }.join(",")
    stories = []
    stories += Story.published.joins(:topics).where("topics.id IN (#{my_topic_ids})").where("user_id != #{self.user_id}") unless my_topic_ids.blank?
    stories
  end
  
  def determine_thumbnail_colors
    begin
      image =  Magick::Image.read(self.thumbnail.url).first
      histogram = image.color_histogram
    
      # sort by decreasing frequency
      sorted = histogram.keys.sort_by {|p| -histogram[p]}
      most_common_color = sorted.last

      rgb = [sorted.last.red / 257,sorted.last.green / 257,sorted.last.blue / 257]
      hex = rgb.inject("") do |code, color|
        code += color.to_s(16).rjust(2, '0').upcase
      end
    
      self.thumbnail_hex_color = hex
    rescue
    end
  end
end