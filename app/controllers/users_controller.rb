class UsersController < ApplicationController
  before_filter :authenticate_user!, :only => [:edit, :update, :update_in_place, :udpate_avatar, :analytics, :feedback]
  before_filter :find_user, :except => [:community, :community_creators, :analytics, :billing_updates, :feedback]
  skip_before_filter :verify_authenticity_token, :only => [:billing_updates, :update_avatar]
  
  def show
    @nav = "me" if @user == current_user
    
    if @user.is_a?(Creator)
      @content = @user.created_stories.newest_first
      @content = @content.published unless @user == current_user
      @supporters = @user.rewards.group_by(&:user).to_a.map {|x| [x.first,x.second.inject(0){|sum,r| sum+r.amount}]}.sort_by(&:second).reverse
    else
      @body_class = "patronage"
      prepare_patronage_data
      render "patronage"
    end
  end
  
  def patronage
    prepare_patronage_data
  end
  
  def patronage_filter # ajax
    @rewards = @user.given_rewards.where(:recipient_id => params[:creator_id]).includes(:story)
    render :partial => "patronage_list"
  end
  
  def activity
    @activity = Activity.by_users([@user]).only_types("'Reward','Impact'").page(params[:page])
  end
  
  def more_activity
    activity = []
    case params[:filter]
    when "all"
      activity = Activity.involving(@user)
    when "impact"
      activity = Activity.on_impact.where(:recipient_id => @user.id)
    when "rewards-given"
      activity = Activity.on_rewards.where(:actor_id => @user.id)
    when "rewards-received"
      activity = Activity.on_rewards.where(:recipient_id => @user.id)
    when "content"
      activity = Activity.on_content.involving(@user)
    when "badges"
      activity = Activity.on_badges.involving(@user)
    when "coins"
      activity = Activity.on_purchases.involving(@user)
    end
    if activity.empty?
      render :text => ""
    else
      activity = activity.page params[:page]
      render activity
    end
  end
  
  def edit
    redirect_to edit_user_path(current_user) and return if current_user != @user
    @nav = "me"
    @sidenav = "profile"
  end
  
  def update
    @user = current_user
    if @user.update_attributes(params[:user])
      redirect_to user_path(@user), :notice => "Info updated!"
    else
      @nav = "me"
      @sidenav = "profile"
      render 'edit'
    end
  end
  
  def update_in_place
    return if params[:update_value].blank?
    return unless ["occupation", "location", "first_name", "last_name", "email", "amazon_email", "tagline"].include?(params[:attribute])
    
    @user = current_user
    if @user.update_attribute(params[:attribute], params[:update_value])
      @user.geocode_if_location_provided if params[:attribute] == "location"
      render :text => params[:update_value]
    else
      render :text => params[:original_value]
    end
  end
  
  def update_avatar
    return if params[:avatar].blank?
    
    @user = current_user
    @user.avatar = params[:avatar]
    if @user.save
      render :json => {:result => "success", :url => @user.avatar.url(:editorial)} and return
    else
      render :json => {:result => "failure", :message => "Unable to save image"} and return
    end
  end
  
  def settings
    redirect_to settings_user_path(current_user) and return if current_user != @user
  end
  
  def update_email_setting
    return unless ["send_reward_notification_emails", "send_digest_emails", "send_message_notification_emails"].include?(params[:attribute])
    
    @user = current_user
    current_value = @user.send params[:attribute]
    @user.update_attribute(params[:attribute], !current_value)
    render :text => ""
  end
  
  def submit_creator_request
    FeedbackMailer.creator_request(@user, params[:description], params[:examples]).deliver
    render :text => ""
  end
  
  def activity_from_friends
    @activity = @user.activity_from_twitter_and_facebook_friends[0..4]
    render :partial => "sidebar_activity"
  end
  
  def content_from_nearbys
    @content = []

    user_ids = @user.nearbys(30).map(&:id).join(",")
    unless user_ids.blank?
      @content = Story.published.newest_first.where("user_id IN (#{user_ids})").limit(3)
    end
    story_ids = @user.given_rewards.map(&:story_id)
    unless story_ids.blank?
      @content.reject!{|s| story_ids.include? s.id}
    end
    
    render :partial => "sidebar_nearby_content"
  end
  
  def similar_to_what_ive_rewarded
    @content = @user.stories_tagged_similarly_to_what_ive_rewarded[0..2]
    render :partial => "sidebar_similar_to_what_ive_rewarded"
  end
  
  def bookmarks
    @sidenav = "bookmarks"
  end
    
  def rewarded
    @rewards = @user.given_rewards
  end
  
  def followers
    @users = @user.subscribers
    @followers = true
    render "following"
  end
  
  def following
    @users = @user.subscribed_to
  end
  
  def content_rewarded_by
    @rewarder = User.find_by_id(params[:rewarder_id])
    @rewards = @rewarder.given_rewards.where(:recipient_id => @user.id)
    render :layout => false
  end
  
  def analytics
    @user = current_user
    @patrons = @user.rewards.group_by {|r| r.user_id}
    @sidenav = "analytics"
    @nav = "me"
  end
  
  def feedback
    if current_user
      FeedbackMailer.give_feedback(params[:comment], current_user).deliver
    end
    render :json => {:success => true}
  end
  
  def billing_updates
    head :ok
  end
  
  private
    
    def find_user
      @user = User.find(params[:id])
      @page_title = @user.name if @user
      @nav = "me" if current_user == @user
      @sidenav = "profile" if current_user.present? && @user == current_user
    end
    
    def prepare_patronage_data
      @users = @user.given_rewards.includes(:recipient).map(&:recipient).uniq
      @rewards = []
      @rewards = @user.given_rewards.where(:recipient_id => @users.first.id).includes(:story) if @users.first
    end
end