class Story < ActiveRecord::Base
  belongs_to :user
  has_and_belongs_to_many :topics
  has_many :purchases
  has_many :bookmarks
  has_many :users_who_bookmarked, :through => :bookmarks, :source => :user
  has_many :recommendations
  has_many :users_who_recommended, :through => :recommendations, :source => :user
    
  validates :title, :presence => true, :length => (2..256)
  validates :excerpt, :length => (2..1024)
  validates :price, :format => /[0-9.,]+/
  
  def free?
    self.price == 0
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