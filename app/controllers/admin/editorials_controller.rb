class Admin::EditorialsController < Admin::BaseController
  
  def new
    @editorial = Editorial.new(:user_id => params[:user])
    render "form"
  end
  
  def create
    content = Story.find(params[:id])
    editorial = Editorial.create(:story_id => content.id, :user_id => content.user_id)
    redirect_to root_path
  end
  
  def edit
    @editorial = Editorial.find(params[:id])
    render "form"
  end
  
  def update
    @editorial = Editorial.find(params[:id])
    if @editorial.update_attributes(params[:editorial])
      redirect_to admin_editorials_path
    else
      render "form"
    end
  end
  
  def destroy
    @editorial = Editorial.find(params[:id])
    @editorial.destroy
    redirect_to admin_editorials_path
  end
end
