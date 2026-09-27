# typed: false
# frozen_string_literal: true

# Idempotent seed for development and test environments.
# Prefer service objects over raw model writes so seeds exercise production business logic.
#
# Run with: bin/rails db:seed

return unless Rails.env.local?
