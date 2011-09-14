class UsersController < ApplicationController
  before_filter :authenticate_user!, :only => [:edit, :update, :analytics]
  before_filter :find_user, :except => [:community, :community_creators, :analytics, :billing_updates]
  skip_before_filter :verify_authenticity_token, :only => :billing_updates
  
  def show
    @creators = @user.given_rewards.for_content.group_by(&:recipient)
  end
  
  def stream #ajax requests
    render @user.following_stream(params[:page])
  end
  
  def edit
    @user = current_user
    @nav = "home"
    @sidenav = "profile"
  end
  
  def update
    @user = current_user
    if @user.update_attributes(params[:user])
      redirect_to bio_user_path(@user), :notice => "Info updated!"
    else
      @nav = "home"
      @sidenav = "profile"
      render 'edit'
    end
  end
  
  def bookmarks
    @sidenav = "bookmarks"
  end
    
  def rewarded
    @rewards = @user.given_rewards
  end
  
  def patrons
    @patrons = @user.patrons[0,10]
  end
  
  def followers
    @users = @user.subscribers
    render "following"
  end
  
  def following
    @users = @user.subscribed_to
  end
  
  def analytics
    @user = current_user
    @patrons = @user.rewards.group_by {|r| r.user_id}
    @sidenav = "analytics"
    @nav = "home"
  end
  
  def community
    @users = []
    @nav = "community"
    
    if params[:tags].present?
      @tags = Story.tagged_with(params[:tags]).tag_counts.order("count DESC").limit(20).sort do |x, y|
        if params[:tags].include?(x.name)
          -1
        else
          1
        end
      end
    else
      @tags = Story.tag_counts.order("count DESC").limit(20)
    end
    
    content_ids = Story.tagged_with(@tags, :any => true).map{|story| story.id}
    return if content_ids.empty?
    @users = User.select("DISTINCT ON(id) users.*").joins("LEFT OUTER JOIN curations ON curations.user_id = users.id").where("curations.story_id IN (#{content_ids.join(',')})").where("curations.type = 'Reward'")
    @users = @users.sort_by{|user| -user.impact}
  end
  
  def community_creators
    # Rewards this week -> rewardees -> top content -> top impacter
    @users = Reward.this_month.order("amount DESC").group_by(&:recipient)
    array_of_users = @users.to_a
    array_of_users.sort_by {|array| array.second.inject(0){|sum,r| sum+r.amount}}
    @users = ActiveSupport::OrderedHash[array_of_users]
  end
  
  def billing_updates
    subscriber_ids = params[:subscriber_ids].split(",")
    subscriber_ids.each do |subscriber_id|
      user = User.find_by_id(subscriber_id)
      user.refresh_from_spreedly if user
    end

    head :ok
  end
  
  private
    
    def find_user
      @user = User.find(params[:id])
      @page_title = @user.name if @user
      @nav = "home"
      @sidenav = "profile" if current_user.present? && @user == current_user
    end
end