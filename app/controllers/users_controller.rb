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
      redirect_to user_path(@user), :notice => "Info updated!"
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
  
  def supporters
    @patrons = @user.patrons[0,10]
    render "patrons"
  end
  
  def followers
    @users = @user.subscribers
    @followers = true
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
    content_ids = get_tags_and_stories
    return if content_ids.empty?
    
    @users = User.select("DISTINCT ON(id) users.*").joins("LEFT OUTER JOIN curations ON curations.user_id = users.id").where("curations.story_id IN (#{content_ids.join(',')})").where("curations.type = 'Reward'")
    @users = @users.sort do |a,b|
      if a.impact != b.impact
        b.impact <=> a.impact
      else
        b.given_rewards.sum(:amount) <=> a.given_rewards.sum(:amount)
      end
    end
  end
  
  def community_creators
    # Tags -> rewards this week -> rewardees -> top content -> top impacter
    
    @users = []
    content_ids = get_tags_and_stories
    return if content_ids.empty?
    
    @users = Reward.where("curations.story_id IN (#{content_ids.join(',')})").where("curations.type = 'Reward'").group_by(&:recipient).to_a
    @users = @users.sort_by {|array| -array.second.inject(0) {|sum,r| r.amount}}
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
    
    def get_tags_and_stories
      if params[:tags].blank?
        @tags = Story.joins(:curations).where("curations.type = 'Reward'").tag_counts.order("count DESC").limit(20) 
      else      
        @tags = Story.joins(:curations).where("curations.type = 'Reward'").tagged_with(params[:tags]).tag_counts.order("count DESC").limit(20).sort do |x, y|
          if params[:tags].include?(x.name)
            -1
          else
            1
          end
        end
      end
      
      return Story.tagged_with(@tags, :any => true).map{|story| story.id}
    end
end