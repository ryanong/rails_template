---
name: system-tests
description: System test patterns using capybara-experience. Use when writing, modifying, or reviewing system/integration tests. Covers Experiences, Capabilities, behavior blocks, multi-actor testing, and driver selection.
---

# System Tests with Capybara Experience

Reference for writing behavior-driven system tests. Read this before writing any system test.

## Architecture Overview

```
Capybara::Experience
  └── ApplicationExperience        # Base class, includes route helpers
        └── UserExperience         # Login flow, user-specific helpers
        └── AdminExperience        # (future) Admin-specific helpers

Capabilities::ProfileSettings      # Module mixed into experiences at test time
Capabilities::SignUp               # Module mixed into experiences at test time
```

System tests use [capybara-experience](https://github.com/ryanong/capybara-experience) to organize test code into three primitives:

- **Experiences** — represent a user role/session. Each gets its own Capybara session.
- **Capabilities** — modules of page-specific interactions, mixed into experiences with `extend`.
- **Behaviors** — labeled blocks grouping related interactions and assertions.

## File Layout

```
test/
  system/*_test.rb                       # System test files
  support/
    application_system_test_case.rb      # Base test case (rack_test driver)
    javascript_system_test_case.rb       # JS test case (cuprite driver)
    experiences/
      application_experience.rb          # Base experience class
      user_experience.rb                 # User login/session helpers
    capabilities/*.rb                    # Profile page interactions
```

## Test Case Base Classes

- **`ApplicationSystemTestCase`** — uses `rack_test` driver. Fast, no JS support. Use for tests that don't need JavaScript.
- **`JavaScriptSystemTestCase`** — uses `cuprite` (headless Chrome). Use for tests that depend on JavaScript, Turbo, or Stimulus.

## Writing an Experience

Experiences inherit from `ApplicationExperience` (which inherits from `Capybara::Experience`). Each experience wraps its own Capybara session — all Capybara and MiniTest::Assertions methods (`visit`, `fill_in`, `click_button`, `assert_text`, etc.) are available directly on the experience instance.

```ruby
# test/support/experiences/user_experience.rb
class UserExperience < ApplicationExperience
  T.unsafe(self).include(Rails.application.routes.url_helpers)

  def login(phone:, country: "US +1")
    visit new_phone_path
    select country, from: "Country code"
    fill_in "Phone number", with: phone
    click_button "Send code"
    assert_text "Enter your code"

    phone_record = PhoneNumber.find_by!(number: PhonyRails.normalize_number(phone, country_code: "US"))
    fill_in "Verification code", with: phone_record.verification_code
    click_button "Verify"
    assert_current_path root_path
  end
end
```

## Writing a Capability

Capabilities are modules encapsulating interactions with a specific page or feature. Use `requires_ancestor { ApplicationExperience }` for Sorbet type safety. Each method in a capability should represent a discrete user action or assertion.

```ruby
# test/support/capabilities/profile_settings.rb
module Capabilities
  module ProfileSettings
    extend T::Helpers
    requires_ancestor { ApplicationExperience }

    def visit_profile
      visit profile_path
    end

    def update_phone_number(new_phone:)
      click_button "Change number"
      fill_in "Phone number", with: new_phone
      click_button "Send code"
      assert_text "Enter your code"

      phone_record = PhoneNumber.find_by!(number: PhonyRails.normalize_number(new_phone, country_code: "US"))
      fill_in "Verification code", with: phone_record.verification_code
      click_button "Verify"
    end
  end
end
```

## Writing a System Test

```ruby
# test/system/profile_test.rb
class ProfileTest < JavaScriptSystemTestCase
  test "logged in user updates their phone number" do
    user_ux = UserExperience().extend(Capabilities::ProfileSettings)

    behavior "user logs in" do
      user_ux.login(phone: "555-123-4567")
    end

    behavior "user updates phone number" do
      user_ux.visit_profile
      user_ux.assert_text "+15551234567"
      user_ux.update_phone_number(new_phone: "555-987-6543")
      user_ux.assert_text "+15559876543"
    end

    assert_equal "+15559876543", users(:one).reload.phone_number.number
  end
end
```

## Multi-Actor Test

Multiple experiences each get their own isolated Capybara session, so you can test interactions between different users in one test:

```ruby
class CollaborationTest < JavaScriptSystemTestCase
  test "host creates event and attendee sees it" do
    host_ux = UserExperience().extend(Capabilities::EventManagement)
    attendee_ux = UserExperience()

    behavior "host creates an event" do
      host_ux.login(phone: "555-111-1111")
      host_ux.create_event(name: "Game Night", spots: 10)
      host_ux.assert_text "Game Night"
    end

    behavior "attendee sees the event" do
      attendee_ux.login(phone: "555-222-2222")
      attendee_ux.visit root_path
      attendee_ux.assert_text "Game Night"
    end
  end
end
```

## Key Patterns

- **Interactions go on the experience**: call `user_ux.click_button`, `user_ux.assert_text`, etc. — not bare Capybara methods. This scopes each action to the correct session.
- **Extend capabilities at test time**: `UserExperience.new.extend(Capabilities::SignUp)` — only mix in what the test needs.
- **Behavior blocks for readability**: wrap related steps in `behavior "description" do ... end`. These read like a user story and make failures easier to locate.
- **Assertions belong in behaviors**: keep assertions close to the action that triggers them, inside the behavior block.
- **Database assertions outside behaviors**: final state checks against the database go after the last behavior block.
- **One test per user flow**: each test should describe one complete user journey. Use behaviors to break it into readable steps.

## When to Use Which Driver

| Scenario | Base Class | Why |
|---|---|---|
| Form submission, link clicks, static content | `ApplicationSystemTestCase` | Fast, no browser overhead |
| Stimulus controllers, Turbo frames/streams | `JavaScriptSystemTestCase` | Needs real JS execution |
| Auto-save, debounced inputs, fetch API | `JavaScriptSystemTestCase` | Needs real JS execution |
| Visual interactions | `JavaScriptSystemTestCase` | Needs real browser rendering |

## Notes

- Animations are disabled by default in JavaScriptSystemTestCase to avoid flaky tests. Don't ever test animation behavior in system tests — it's a UI detail that doesn't affect functionality.
