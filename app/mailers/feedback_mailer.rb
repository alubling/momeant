class FeedbackMailer < ActionMailer::Base
  default :from => "Momeant <team@momeant.com>"
  
  def give_feedback(comment, user)
    @comment = comment
    @user = user
    
    mail :to => "support@momeant.com", :from => "#{@user.name} <#{@user.email}>", :subject => "User Feedback"
  end
  
  def creator_request(user, description, examples)
    @user = user
    @description = description
    @examples = examples
    
    mail :to => "team@momeant.com", :from => "#{@user.name} <#{@user.email}>", :subject => "Creator Request"
  end
end
