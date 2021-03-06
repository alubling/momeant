require 'uri'
require 'cgi'

class RewardsController < ApplicationController
  before_filter :authenticate_user!, :except => [:visualize]
  
  def create
    @user = User.find_by_id(params[:user_id])
    return if @user.nil?
    amount = params[:reward][:amount].gsub('$','').to_f
    
    if amount < 1
      render json: { success: false, modal: "Sorry! $1.00 is the minimum reward allowed." } and return
    elsif amount > 99
      render json: { success: false, modal: "Sorry! $99.00 is the maximum reward allowed, for now." } and return
    end
    
    impacted_by = nil
    query = URI.parse(params[:reward][:content_url]).query
    impacted_by = CGI.parse(query)["impacted_by"] if query
    
    begin
      @reward = current_user.reward(@user, amount, impacted_by, params[:reward][:content_url])
    rescue Exceptions::AmazonPayments::InsufficientBalanceException
      render json: { success: false, modal: render_to_string(partial: "rewards/modal/errors/need_to_reauthorize") }
      return
    end
    
    if !@reward
      @error = "Oh, shoot! There was an error in processing your reward."
      render json: { success: false, modal: @error } and return
    end
        
    NotificationsMailer.reward_notice(@reward).deliver if @user.send_reward_notification_emails?
    if current_user.given_rewards.count == 1
      NotificationsMailer.first_reward_given(@reward).deliver
    elsif !current_user.has_configured_postpaid? && !current_user.is_under_pledged_rewards_stop_threshold?
      previous_rewards = current_user.given_rewards.pledged.includes(:recipient)
      NotificationsMailer.pledged_limit_reached(current_user, previous_rewards).deliver
    end
    
    @twitter_configured = current_user.authentications.find_by_provider("twitter")
    @facebook_configured = current_user.authentications.find_by_provider("facebook")
    json = {
      success: true,
      reward_id: @reward.id,
      html: render_to_string(partial: "rewards/modal/after_reward")
    }
    json[:modal] = render_to_string(partial: "rewards/modal/first_reward") if current_user.given_rewards.count == 1
    render json: json
  end
  
  def visualize
    @reward = Reward.find_by_id(params[:id])
    render :partial => "rewards/visualize", :layout => false
  end
end