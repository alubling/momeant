Factory.define :purchase do |purchase|
  purchase.story    { Factory(:story) }
  purchase.payee    { |p| p.story.user }
  purchase.payer    { Factory(:email_confirmed_user) }
  purchase.amount   { |p| p.story.price }
end

Factory.define :pay_period do |pay_period|
  pay_period.end        { 1.month.ago }
  pay_period.user       { Factory(:admin) }
  pay_period.line_items { [Factory(:line_item), Factory(:line_item)] }
end

Factory.define :line_item, :class => "PayPeriodLineItem" do |line_item|
  line_item.payee   { Factory(:creator) }
  line_item.amount  { 50.0 }
end