ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

require 'rake'
require 'rails/test_help'
require 'shoulda'
require 'coulda'
require 'factory_girl'
require 'capybara/rails'

Coulda.default_testcase_class = ActionController::IntegrationTest

# Load shared test steps for Coulda
FileList[File.expand_path('integration/steps/**/*_steps.rb', File.dirname(__FILE__))].each do |f|
  require f
end

class ActionController::IntegrationTest
  include Capybara
end

class ActionController::TestCase
  include Devise::TestHelpers
end

class ActiveSupport::TestCase
  
  Factory.find_definitions

  # Add more helper methods to be used by all tests here...
end