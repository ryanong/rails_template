# typed: false
# frozen_string_literal: true

require "rails/generators"

class PackGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def create_package_yml
    template "package.yml.tt", "packs/#{pack_name}/package.yml"
  end

  def create_engine
    template "engine.rb.tt", "packs/#{pack_name}/lib/#{pack_name}_engine.rb"
  end

  def create_app_directory
    empty_directory "packs/#{pack_name}/app"
  end

  def create_test_directory
    empty_directory "packs/#{pack_name}/test"
  end

  private

  def pack_name
    file_name
  end

  def engine_class_name
    "#{pack_name.camelize}Engine"
  end
end
