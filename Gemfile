source "https://rubygems.org"

# Core
gem "rails", "~> 8.1.4"
gem "puma", ">= 5.0"
gem "sqlite3", ">= 2.1"
gem "bootsnap", require: false
gem "faraday"
gem "tzinfo-data", platforms: %i[windows jruby]

# Frontend
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 4.4"
gem "tailwind_merge", "~> 1.4"
gem "jbuilder"
gem "view_component"

# Background jobs, caching, and cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Deployment
gem "kamal", require: false
gem "thruster", require: false

# Authorization and sessions
gem "action_policy"
gem "activerecord-session_store"

# Storage
gem "image_processing"
gem "active_storage_validations"

# Rails Extensions
gem "rails-uuid-pk", "~> 0.13.0", require: "rails_uuid_pk"

# Type checking
gem "sorbet-runtime"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-capybara", require: false
  gem "rubocop-minitest", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-sorbet", require: false
  gem "tapioca", require: false
  gem "packs"
end

group :development do
  gem "annotaterb", require: false
  gem "sorbet"
  gem "lookbook"
  gem "listen"
  gem "actioncable"
  gem "ruby-lsp"
  gem "web-console"
  gem "packwerk", require: false
  gem "packwerk-extensions", require: false
end

group :test do
  gem "capybara"
  gem "capybara-experience"
  gem "selenium-webdriver"
  gem "cuprite"
  gem "imagen", github: "ryanong/imagen_rb", branch: "support-prism", require: false # for ruby support > 3.3 for undercover
  gem "minitest-reporters"
  gem "rack_session_access"
  gem "undercover", require: false
  gem "simplecov"
  gem "spy"
  gem "webmock"
end
