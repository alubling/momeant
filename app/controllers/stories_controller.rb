class StoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :get_topics, :only => [:new]
  
  def new
    @story = Story.new
  end
  
  def create
    @story = Story.new(params[:story])
    attach_topics
    if current_user.stories << @story
      redirect_to preview_story_path(@story), :notice => "Great story!"
    else
      get_topics
      render "new"
    end
  end
  
  def preview
    @story = Story.find(params[:id])
  end
  
  def index
    @stories = current_user.stories
  end
  
  private
    def get_topics
      @topics = Topic.all
    end
    
    def attach_topics
      topic_ids = params[:topics]
      if topic_ids
        @story.topics << Topic.where("id IN (#{topic_ids.keys.join(',')})")
      end
    end
  
end