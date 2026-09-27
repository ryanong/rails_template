# typed: false

require "capybara/experience/minitest"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Capybara::Experience::MinitestHooks

  driven_by :rack_test
end
