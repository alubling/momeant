require File.expand_path('../test_helper', File.dirname(__FILE__))

Feature "A Creator can create a story", :testcase_class => FullStackTest do
  extend StoryCreationSteps
  
  in_order_to "share my stories with others"
  as_a "creator or admin"
  i_want_to "create momeant stories"
    
  Scenario "A Creator creates a new story" do
    given_a :creator
    given_a :topic
    given_im_signed_in_as :creator
    
    when_i_visit_page :new_story
        
    And "I fill out the story title, excerpt, topics and price" do
      fill_in "story_title", :with => "Little Red Riding Hood"
      fill_in "story_excerpt", :with => "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor."
      check "topics_#{@topic.id}"
      fill_in "story_price", :with => "0.50"
    end
    
    and_i_open_the_page_editor
    
    and_i_choose_the_title_theme_and_fill_in_a_title_for_page(1)
    
    and_i_goto_the_next_page
    
    and_i_choose_the_image_theme_and_choose_an_image_and_caption_for_page(2)
    
    and_i_goto_the_next_page
    
    and_i_choose_the_pullquote_theme_and_fill_in_a_quote_for_page(3)
    
    and_i_goto_the_next_page
    
    and_i_choose_the_video_theme_and_fill_in_a_vimeo_id_for_page(4)
    
    and_i_close_the_page_editor
    
    And "I click Create Story" do
      click_button "Create Story"
    end
    
    then_i_should_be_on_page(:preview_story) { Story.last }
    
    And "The data should be properly stored and linked" do
      @story = Story.last
      assert @creator.created_stories.include?(@story)
      assert_equal 4, @story.pages.count 
    end
        
    And "I should see my story information" do
      assert page.has_content? "Little Red Riding Hood"
      assert page.has_content? "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor."
      assert page.has_content? @topic.name
    end
  end
  
  Scenario "A regular user (non-Creator) tries to access the new story page" do
    given_a(:email_confirmed_user)
    
    given_im_signed_in_as(:email_confirmed_user)
    
    when_i_visit_page(:new_story)
    
    then_i_should_be_on_page(:home)
    
    then_i_should_see_flash(:alert, "You are not authorized to access this page.")
  end
  
  Scenario "A creator tries to create a story but forgets a title and excerpt" do
    given_a :creator
    given_a :topic
    given_im_signed_in_as :creator
    
    when_i_visit_page :new_story
    
    and_i_open_the_page_editor
    
    and_i_choose_the_title_theme_and_fill_in_a_title_for_page(1)
    
    and_i_goto_the_next_page
    
    and_i_choose_the_image_theme_and_choose_an_image_and_caption_for_page(2)
    
    and_i_goto_the_next_page
    
    and_i_choose_the_pullquote_theme_and_fill_in_a_quote_for_page(3)
    
    and_i_goto_the_next_page
    
    and_i_choose_the_video_theme_and_fill_in_a_vimeo_id_for_page(4)
    
    and_i_close_the_page_editor
    
    And "I click Create Story" do
      click_button "Create Story"
    end
    
    Then "I should be back on the new story page and my page content should still be there" do
      assert_equal "Little Red Riding Hood", find("#pages_1_title").value
      assert_equal "Here is an explanation of what this image is", find("#pages_2_caption").value
      excerpt = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
      assert_equal excerpt, find("#pages_3_quote").value
      assert_equal "18427511", find("#pages_4_vimeo_id").value
    end
  end
  
end