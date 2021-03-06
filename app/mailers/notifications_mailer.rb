class NotificationsMailer < ActionMailer::Base
  include ActionView::Helpers::NumberHelper
  
  default :from => "Momeant <team@momeant.com>"
  layout "email"
  
  def welcome_to_momeant(user)
    mail :to => user.email, :subject => "Welcome to Momeant!"
  end
  
  def first_reward_given(reward)
    @rewarder = reward.user
    @creator = reward.recipient
    mail to: @rewarder.email, subject: "Paying for your reward to #{@creator.name}"
  end
  
  def payment_configured(user)
    mail to: user.email, subject: "Payment method configured"
  end
  
  def reward_notice(reward)
    @reward = reward
    @messaging_url = new_message_url(user: @reward.user_id)
    @user_for_email_settings = @reward.recipient
    
    mail :to => @reward.recipient.email, :subject => "You were just rewarded on Momeant!"
  end
  
  def message_notice(message)
    @message = message
    @messaging_url = message_url(message.parent_or_self)
    @user_for_email_settings = @message.recipient
    
    mail :to => @message.recipient.email, :subject => "#{message.sender.name} just messaged you on Momeant!"
  end
  
  def impact_notice(user, reward)
    @user = user
    @reward = reward
    @creator_url = user_url(@reward.recipient)
    
    mail to: @user.email, subject: "You just made an impact!"
  end
  
  def site_updated(user)
    mail :to => user.email, :subject => "Momeant has a new face!"
  end
  
  def pledged_reminder(user, rewards)
    @user = user
    @rewards = rewards
    @amount = @rewards.map(&:amount).inject(:+)
    
    mail :to => user.email, :subject => "Here's your chance to pay for your pledged rewards!"
  end
  
  def pledged_limit_reached(user, rewards)
    @user = user
    @rewards = rewards
    @amount = @rewards.map(&:amount).inject(:+)
    
    mail :to => user.email, :subject => "Please configure your payment method."
  end
  
  def new_follower(user, follower)
    @user = user
    @follower = follower
    @user_for_email_settings = @user
    
    mail :to => user.email, :subject => "#{follower.name} is now following you on Momeant."
  end
  
  def content_from_following(user, following, content)
    @user = user
    @following = following
    @content = content
    @user_for_email_settings = @user
    @dont_pad_email = true
    
    mail :to => user.email, :subject => "#{following.name} just shared #{@content.new_article_string}."
  end
  
  def broadcast_from_following(user, following, broadcast)
    @user = user
    @following = following
    @broadcast = broadcast
    @user_for_email_settings = @user
    @dont_pad_email = true
    
    mail :to => user.email, :subject => "#{following.name} just posted a new broadcast message."
  end
  
  def payment_notice(user, amount)
    @user = user
    @amount = number_to_currency(amount)
    
    mail to: user.email, subject: "Momeant just paid you #{@amount}!"
  end
  
  def payment_error(user)
    @user = user
    
    mail to: user.email, subject: "Action Needed! Your Amazon Payment method was declined."
  end
  
  def thank_you_level_achieved(creator, user, level)
    @creator = creator
    @user = user
    @level = level
    @messaging_url = new_message_url(user: @user.id)
    
    mail to: @creator.email, subject: "A supporter achieved your Thank You Level"
  end
  
  def flexible_email(to, from, subject, body)
    @contents = body
    Rails.logger.info @contents
    
    mail to: to, from: from, subject: subject
  end
end