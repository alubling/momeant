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
      fill_in "story_tag_list", :with => "1st tag, 2nd tag, 3rd tag"
    end
    
    and_i_open_the_page_editor
    
    and_i_choose_the_title_theme_and_fill_in_a_title_for_page(1)
    
    and_i_goto_the_next_page
    
    and_i_choose_the_image_theme_and_choose_an_image_and_caption_for_page(2)
    
    and_i_goto_the_next_page
    
    and_i_choose_the_pullquote_theme_and_fill_in_a_quote_for_page(3)
    
    and_i_goto_the_next_page
    
    and_i_choose_the_video_theme_and_fill_in_a_vimeo_id_for_page(4)
    
    and_i_goto_the_next_page
    
    and_i_choose_the_split_theme_and_choose_a_picture_and_text_for_page(5)
    
    and_i_goto_the_next_page
    
    and_i_choose_the_grid_theme_and_choose_pictures_and_text_for_page(6)
    
    and_i_close_the_page_editor
    
    And "I click Create Story" do
      click_button "Create Story"
    end
    
    then_i_should_be_on_page(:preview_story) { Story.last }
    
    And "The data should be properly stored and linked" do
      @story = Story.last
      assert @creator.created_stories.include?(@story)
      assert_equal 6, @story.pages.count
    end
        
    And "I should see my story information" do
      assert page.has_content? "Little Red Riding Hood"
      assert page.has_content? "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor."
      assert page.has_content? @topic.name
      ["1st tag", "2nd tag", "3rd tag"].each do |tag|
        assert page.has_content? tag
      end
    end
    
    And "My story should be in the draft state" do
      assert !@story.published?
    end
      
    And "I should see a publish button" do
      assert find_button('Publish this story').visible?
    end
  end
  
  Scenario "A creator publishes a story currently in draft state" do
    given_a :creator
    Given "A story I've created" do
      @draft_story = Factory(:draft_story, :user => @creator)
    end
    given_im_signed_in_as :creator
    
    When "I visit the preview page for my story" do
      visit preview_story_path(@draft_story)
    end
    
    And "I click the 'Publish story' button" do
      click_button "Publish this story"
    end
    
    Then "I should be back on the preview page" do
      assert_equal preview_story_path(@draft_story), current_path
    end
    
    And "My story should be published" do
      @draft_story.reload
      assert @draft_story.published?
    end
  end
  
  Scenario "A regular user (non-Creator) tries to access the new story page" do
    given_a(:email_confirmed_user)
    
    given_im_signed_in_as(:email_confirmed_user)
    
    when_i_visit_page(:new_story)
    
    then_i_should_be_on_page(:home)
    
    then_i_should_see_flash(:alert, "You are not authorized to access this page.")
  end
  
  Scenario "A creator tries to create a story but forgets to fill in some required fields" do
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
    
    and_i_goto_the_next_page
    
    and_i_choose_the_split_theme_and_choose_a_picture_and_text_for_page(5)
    
    and_i_goto_the_next_page
    
    and_i_choose_the_grid_theme_and_choose_pictures_and_text_for_page(6)
    
    and_i_close_the_page_editor
    
    And "I click Create Story" do
      click_button "Create Story"
    end
    
    Then "My page content should still be there when it goes back to the form" do
      assert_equal "Little Red Riding Hood", find("#pages_1_title").value
      assert_equal "Here is an explanation of what this image is", find("#pages_2_caption").value
      excerpt = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
      assert_equal excerpt, find("#pages_3_quote").value
      assert_equal "18427511", find("#pages_4_vimeo_id").value
      assert_equal excerpt, find("#pages_5_text").value
      8.times do |num|
        cell = num + 1
        assert_equal "Lorem ipsum dolor sit amet", find("#pages_6_cells_#{cell}_text").value
      end
    end
  end
  
end