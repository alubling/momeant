class Advert < ActiveRecord::Base
  validates_presence_of :title
  validates_presence_of :path
  validates_attachment_presence :image
  
  has_attached_file :image,
    :styles => { :medium => "470x160#" },
    :path          => "adverts/:id/:style.:extension",
    :storage        => :s3,
    :s3_credentials => {
      :access_key_id       => ENV['S3_KEY'],
      :secret_access_key   => ENV['S3_SECRET']
    },
    :bucket        => ENV['S3_BUCKET']
  
  PATHS = {
    "FAQ page" => "faq"
  }.freeze
  
  scope :gimme_two, :order => "RANDOM()", :limit => 1
end
