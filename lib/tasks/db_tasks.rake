namespace :momeant do
  namespace :db do
    
    desc "Insert a few sample topics"
    task :seed_topics => :environment do
      art = Topic.create(:name => "Art")
      Topic.create(:name => "Photography", :topic_id => art.id)
      Topic.create(:name => "Painting", :topic_id => art.id)
      Topic.create(:name => "Sculpture", :topic_id => art.id)
      Topic.create(:name => "Illustration", :topic_id => art.id)
      Topic.create(:name => "Business")
      Topic.create(:name => "Culture")
      design = Topic.create(:name => "Design")
      Topic.create(:name => "Fashion", :topic_id => design.id)
      Topic.create(:name => "Graphic Design", :topic_id => design.id)
      Topic.create(:name => "DIY")
      Topic.create(:name => "Education")
      Topic.create(:name => "Environment")
      Topic.create(:name => "Gastronomy")
      Topic.create(:name => "Health")
      Topic.create(:name => "History")
      Topic.create(:name => "Literature")
      Topic.create(:name => "Music")
      Topic.create(:name => "Journalism")
      Topic.create(:name => "Science")
      Topic.create(:name => "Sports")
      Topic.create(:name => "Technology")
      Topic.create(:name => "Travel")
    end
    
    desc "Copy twitter and facebook ids from the authentications table and cache it on the user"
    task :cache_auth_ids_on_user => :environment do
      Authentication.all.each do |auth|
        auth.user.update_attribute("#{auth.provider}_id", auth.uid)
      end
    end
    
    desc "Geocode users with existing locations"
    task :geocode_users => :environment do
      User.where("location IS NOT NULL").each do |user|
        user.geocode
        user.save
      end
    end
    
    desc "Update user avatars"
    task :update_user_avatars => :environment do
      User.all.each {|u| u.reload_avatar }
    end
    
    desc "Store impact cache counts for all impact previously given from a user to another"
    task :backdate_impact_caches => :environment do
      Reward.order("created_at ASC").each do |reward|
        reward.cache_impact!
      end
    end
  end
  
  namespace :activity do
    desc "Create Activity records for past actions"
    task :backdate => :environment do
      Activity.destroy_all
      
      Reward.all.each do |reward|
        Activity.create(
          :actor_id => reward.user_id,
          :recipient_id => reward.recipient_id,
          :action_type => "Reward",
          :action_id => reward.id,
          :created_at => reward.created_at)
        
        reward.ancestors.each do |ancestor|
          Activity.create(
            :recipient_id => ancestor.user_id,
            :action_type => "Impact",
            :action_id => reward.id,
            :created_at => ancestor.created_at)
        end
      end
      
      Story.published.each do |story|
        Activity.create(
          :actor_id => story.user_id,
          :action_type => "Story",
          :action_id => story.id,
          :created_at => story.created_at)
      end
      
      AmazonPayment.paid.each do |payment|
        Activity.create(
          :actor_id => payment.payer_id,
          :action_type => "AmazonPayment",
          :action_id => payment.id,
          :created_at => payment.created_at)
      end
    end
  end
  
  namespace :emails do
    desc "Send site update email"
    task :send_site_update => :environment do
      User.all.each {|u| NotificationsMailer.site_updated(u).deliver }
    end
  end
  
  namespace :comments do
    desc "Copy existing rewards with comments to Comment records"
    task :copy_from_rewards => :environment do
      Reward.all.each do |reward|
        unless reward.comment.blank?
          Comment.create(
            :comment => reward.comment,
            :user_id => reward.user_id,
            :reward_id => reward.id,
            :commentable_id => reward.story_id,
            :commentable_type => "Story"
          )
        end
      end
    end
  end
  
  desc "Apply old logic of image/text template to new code"
  task :assign_story_preview_types => :environment do
    Story.all.each do |story|
      if story.media_type == "photos" || story.media_type == "videos"
        story.update_attribute(:preview_type, "image")
      else
        story.update_attribute(:preview_type, "text")
      end
    end
  end
end