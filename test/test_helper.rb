# typed: false

if ENV["COVERAGE"] == "1"
  require "simplecov"
  require "packs"
  require "undercover/simplecov_formatter"

  SimpleCov.start do
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::SimpleFormatter,
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Undercover
    ])

    add_filter %r{\Apacks/.*/(test|features|spec|autotest)/}
    add_filter %r{\Aconfig/}
    add_filter %r{\Adb/}
    add_filter "app/components/ruby_ui"

    Packs.all.each do |pack|
      add_group pack.name, pack.relative_path.to_s
    end

    track_files "{app,lib,packs}/**/*.rb"

    enable_for_subprocesses true
  end
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "spy/integration"
require "webmock/minitest"

WebMock.disable_net_connect!(allow_localhost: true)

Dir[Rails.root.join("test/support/**/*.rb")].each { |f| require f }

Minitest::Reporters.use!(
  Minitest::Reporters::DefaultReporter.new,
  ENV,
  Minitest.backtrace_filter
)

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    if ENV["COVERAGE"] == "1"
      parallelize_setup do |worker|
        SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
      end

      parallelize_teardown do |worker|
        SimpleCov.result
      end
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end
