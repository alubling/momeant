Factory.sequence :last_name do |n|
  "Doe#{n}"
end

Factory.define :user do |user|
  user.password               "password"
  user.password_confirmation  "password"
  user.first_name             'John'
  user.last_name              { Factory.next(:last_name) }
  user.username               { |u| u.name.delete(' ').underscore }
  user.email                  { |u| "#{u.username}@example.com" }
end

Factory.define :email_confirmed_user, :parent => :user do |user|
  user.confirmation_token     nil
  user.confirmed_at           Time.now - 1.day
end

Factory.define :creator, :parent => :email_confirmed_user, :class => "Creator" do |creator|
  creator.first_name          'Creator'
end

Factory.define :admin, :parent => :email_confirmed_user do |admin|
  admin.first_name            'Admin'
  admin.is_admin              'true'
end