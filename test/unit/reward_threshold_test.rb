require 'test_helper'

class RewardThresholdTest < ActiveSupport::TestCase
  
  test "A user who rewards an amount under their stop threshold can continue to reward" do
    user = Factory(:user)
    story = Factory(:story)
    user.reward(story, 0.90)
    assert user.is_under_pledged_rewards_stop_threshold?
    assert user.reward(story, 0.20)
  end
  
  test "A user who rewards an amount pushing them over their stop threshold can no longer reward" do
    user = Factory(:user)
    story = Factory(:story)
    user.reward(story, 10.20)
    assert !user.is_under_pledged_rewards_stop_threshold?
    assert !user.reward(story, 0.20)
  end
  
  test "Once a user pays for their unfunded rewards, their stop threshold resets" do
    user = Factory(:user)
    story = Factory(:story)
    user.reward(story, 10.20)
    assert !user.is_under_pledged_rewards_stop_threshold?
    fake_amazon_payment_id = 1
    user.pay_for_pledged_rewards!(fake_amazon_payment_id)
    assert user.is_under_pledged_rewards_stop_threshold?
    assert user.reward(story, 0.20)
  end
  
end