class CommunityController < ApplicationController
  
  def content
    @stories = Story.published.most_rewarded.limit(12)

    if params[:tag]
      @stories = @stories.tagged_with(params[:tag])
    else
      @tags = Story.tag_counts.order("count DESC").limit(10)
    end
  end
  
  def people
    @users = User.select("DISTINCT ON(id) users.*").joins("LEFT OUTER JOIN curations ON curations.user_id = users.id").where("curations.type = 'Reward'").limit(12) #.where("curations.created_at > '#{30.days.ago}'")

    if params[:tag]
      @users = @users.tagged_with(params[:tag])
    else
      @tags = User.interest_counts.order("count DESC").limit(10)
    end

    @users = @users.sort do |a,b|
      if a.impact != b.impact
        b.impact <=> a.impact
      else
        b.given_rewards.sum(:amount) <=> a.given_rewards.sum(:amount)
      end
    end
    @users = @users[0..18]
  end
  
end