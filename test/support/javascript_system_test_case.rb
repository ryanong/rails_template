# typed: false

require "capybara/cuprite"

Capybara.disable_animation = true

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [ 1400, 900 ], headless: true)
end

class JavaScriptSystemTestCase < ApplicationSystemTestCase
  driven_by :cuprite
end
