# typed: true
# frozen_string_literal: true

require "active_job/arguments"
require "active_support/core_ext/integer/time"
require "bootsnap/setup"
require "bundler/setup"
require "capybara/cuprite"
require "capybara/experience"
require "capybara/experience/minitest"
require "ferrum"
require "rails/all"
require "spy/integration"
require "tailwind_merge"
require "undercover/simplecov_formatter"
require "webmock/minitest"

require "rails/generators"
require "rails/generators/named_base"
require "rails/generators/actions"
