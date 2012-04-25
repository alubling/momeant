class RegistrationsController < Devise::RegistrationsController
  
  def create
    resource = User.new(params[:user])
    resource.coins = 0
    resource.subscription_last_updated_at = Time.now
    
    if resource.save
      # track signup analytics across the redirect
      flash[:track_signup] = true
      
      NotificationsMailer.welcome_to_momeant(resource).deliver
      
      sign_in_and_redirect(resource_name, resource)
    else
      @user = resource
      clean_up_passwords(resource)
      flash[:alert] = @user.errors.full_messages
      setup_landing
      render "home/landing"
    end
  end
  
end