# typed: true
# frozen_string_literal: true

class ApplicationExperience < Capybara::Experience
  T.unsafe(self).include(Rails.application.routes.url_helpers)
end
