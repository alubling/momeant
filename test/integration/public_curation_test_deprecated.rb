require File.expand_path('../test_helper', File.dirname(__FILE__))

include ActionView::Helpers::TextHelper

Feature "A user wants to publicly curate for others", :testcase_class => FullStackTest do

  in_order_to "share the content I like with others"
  as_a "user"
  i_want_to "be able to recommend and like stories and see the list later"
  
  Scenario "A user recommends a story" do
    given_a(:email_confirmed_user)
    given_a(:story)
    Given "I own the story" do
      Purchase.create(:story => @story, :payer => @email_confirmed_user)
    end
    
    given_im_signed_in_as(:email_confirmed_user)
    
    When "I visit the story preview page" do
      visit preview_story_path(@story)
    end
    
    And "I click the recommend button" do
      click_link(pluralize(@story.recommendations.count, "recommendation"))
    end
    
    And "I fill out a comment as to why I recommend this story and hit the Recommend story button" do
      fill_in "comment", :with => "Because it's so much fun!"
      click_button "Recommend story"
    end
    
    Then "I should be on the story preview page" do
      assert_equal preview_story_path(@story), current_path
    end
    
    And "the story should be in my recommended stories" do
      assert @email_confirmed_user.recommended_stories.include?(@story)
    end
    
    And "the user should be in the story's users who recommended" do
      assert @story.users_who_recommended.include?(@email_confirmed_user)
    end
    
    And "the recommendation should have the comment assigned to it" do
      assert_equal "Because it's so much fun!", Recommendation.last.comment
    end
    
    when_i_visit_page(:recommended_stories)
    
    then_i_should_be_on_page(:recommended_stories)
    
    And "I should see a link to my recommended story" do
      assert page.find_link(@story.title).visible?
    end
  end
  
  Scenario "A user unrecommends a story they previously recommended" do
    given_a(:email_confirmed_user)
    given_a(:story)
    Given "A recommendation already exists for this story/user" do
      Recommendation.create(:story_id => @story.id, :user_id => @email_confirmed_user.id)
    end
    
    given_im_signed_in_as(:email_confirmed_user)
    
    When "I visit the story preview page" do
      visit preview_story_path(@story)
    end
    
    And "I click the unrecommend button" do
      click_link(pluralize(@story.recommendations.count, "recommendation"))
    end
    
    Then "I should be on the story preview page" do
      assert_equal preview_story_path(@story), current_path
    end
    
    And "the story should not be in my recommended stories" do
      assert !@email_confirmed_user.recommended_stories.include?(@story)
    end
    
    And "the user should not be in the story's users who recommended" do
      assert !@story.users_who_recommended.include?(@email_confirmed_user)
    end
  end
  
  Scenario "A user has reached their limit of recommendations" do
    given_a(:email_confirmed_user)
    given_a(:story)
    Given "A second story" do
      @story2 = Factory(:story)
    end
    Given "10 recommendations already exist for this story/user" do
      10.times do
        Recommendation.create(:story_id => @story.id, :user_id => @email_confirmed_user.id)
      end
    end
    
    given_im_signed_in_as(:email_confirmed_user)
    
    When "I visit the story preview page" do
      visit preview_story_path(@story2)
    end
    
    Then "I should see that my recommendation limit is reached" do
      assert page.has_content?("Recommendation limit reached")
    end
  end
  
  Scenario "A user likes a story" do
    given_a(:email_confirmed_user)
    given_a(:story)
    Given "I own the story" do
      Purchase.create(:story => @story, :payer => @email_confirmed_user)
    end
    
    given_im_signed_in_as(:email_confirmed_user)
    
    When "I visit the story preview page" do
      visit preview_story_path(@story)
    end
    
    And "I click the like button" do
      click_link(pluralize(@story.likes.count, "heart"))
    end
    
    Then "I should be on the story preview page" do
      assert_equal preview_story_path(@story), current_path
    end
    
    And "the story should be in my liked stories" do
      assert @email_confirmed_user.liked_stories.include?(@story)
    end
    
    And "the user should be in the story's users who liked" do
      assert @story.users_who_liked.include?(@email_confirmed_user)
    end
  end
  
  Scenario "A user unlikes a story they've previously liked" do
    given_a(:email_confirmed_user)
    given_a(:story)
    Given "A like already exists for this story/user" do
      Like.create(:story_id => @story.id, :user_id => @email_confirmed_user.id)
    end
    
    given_im_signed_in_as(:email_confirmed_user)
    
    When "I visit the story preview page" do
      visit preview_story_path(@story)
    end
    
    And "I click the unlike button" do
      click_link(pluralize(@story.likes.count, "heart"))
    end
    
    Then "I should be on the story preview page" do
      assert_equal preview_story_path(@story), current_path
    end
    
    And "the story should not be in my liked stories" do
      assert !@email_confirmed_user.liked_stories.include?(@story)
    end
    
    And "the user should not be in the story's users who liked" do
      assert !@story.users_who_liked.include?(@email_confirmed_user)
    end
  end
  
end