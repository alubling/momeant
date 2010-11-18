class Story < ActiveRecord::Base
  belongs_to :user
  
  validates :title, :presence => true, :length => (2..256)
  validates :excerpt, :length => (2..1024)
end