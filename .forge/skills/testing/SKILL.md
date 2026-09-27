---
name: testing
description: When writing or editing tests in this codebase, refer to this guide for best practices and patterns. Covers Minitest conventions, test organization, fixtures vs factories, testing background jobs and notifications, and tips for testing service objects, controllers, and views.
---

## Testing Conventions

### General Principles

- Tests live in `test/` using Minitest (Rails default)
- Run tests with `bin/rails test`; run a single file with `bin/rails test test/path/to/file_test.rb`
- Every feature or bug fix must include tests — no code lands without coverage
- Tests are documentation: a reader should understand the feature solely from its tests
- Consolidate system/controller tests into as few happy path flows as possible — one end-to-end flow can cover create, edit, and show if they're naturally sequential
- When planning tasks, each feature section starts with TDD: update an existing passing system test to fail, or write a new minimal failing system test, then implement to make it pass
- Prefer extending an existing system/controller test file over creating new ones when the flows are related

### Structure & Organization

- One test file per class/module, mirroring `app/` structure under `test/`
- Use descriptive test names that state the behavior: `test "creates event with valid attributes"`
- Group related assertions in a single test when they share setup; split into separate tests when they describe distinct behaviors
- Keep test files focused — if a test file exceeds ~200 lines, look for extraction opportunities

### Spec Traceability

Use `# @spec <folder>` comments to link tests back to OpenSpec specs (folders in `openspec/specs/`). Only tag tests that **directly verify** a spec's acceptance criteria or core behavior — skip the tag for tests that are tangentially related.

- **Format**: `# @spec <spec>` or `# @spec <spec>:<Scenario name>` to reference a specific scenario
- **Multiple specs**: comma-separated — `# @spec phone-identity, verification-codes`
- **Multiple scenarios**: `# @spec phone-identity:Reject duplicate phone number, verification-codes:Generate code`
- **File-level tag**: when the entire test file maps to a single spec, place the tag at the top of the file
- **Inline tag**: when only some tests in a file are spec-relevant, place the tag above individual tests or groups
- **When to omit**: model validations, helper methods, or other tests that support a spec indirectly but don't verify its key behaviors

### Test Levels (Testing Pyramid, low to high)

- **Unit tests** (models, services, POROs): the bulk of the suite. Fast, isolated, no HTTP stack.
- **Controller tests**: verify request/response, status codes, redirects, and assigned data. Keep assertions on behavior, not implementation. Don't add controller tests for flows already covered by system tests — avoid duplicating coverage.
- **Integration/system tests**: cover critical user flows end-to-end. Use Capybara for browser-level tests sparingly — they're slow.

### Writing Good Tests (Pivotal Labs Style)

- **Arrange-Act-Assert**: clearly separate setup, action, and expectation in every test
- **One assertion per behavior**: each test should verify one logical behavior. Multiple `assert` calls are fine if they describe the same behavior.
- **Test behavior, not implementation**: assert on outcomes (database state, response, side effects), not method call counts or internal structure
- **Minimal setup**: only create what the test actually needs. Avoid elaborate fixtures or god-factories with dozens of attributes.
- **No mystery guests**: make all relevant data visible in the test body. If a value matters to the assertion, set it explicitly — don't rely on hidden defaults.
- **Intention-revealing names**: test names should describe the *what* and *why*, not the *how*: `test "rejects event in the past"` over `test "validation"`
- **Fast feedback**: tests should run fast. Avoid unnecessary database writes (use `build` over `create` when persistence isn't needed), stub external services, and keep the suite under a few seconds.
- **No logic in tests**: no conditionals, or complex calculations. Tests should be linear and obvious.
- **Avoid loops unless matrix testing**: don't loop in tests unless testing a list of inputs and expectations
- **DRY is not a goal in tests**: prefer duplication over the wrong abstraction. Extract shared setup only when 3+ tests share identical context, and use `setup` blocks for it.

### Fixtures & Factories

- Prefer Rails fixtures (`test/fixtures/`) for stable reference data
- Use factories (if added) for tests that need varied or dynamic data
- Keep fixture data minimal and meaningful — every attribute should serve a purpose

### System Tests

- System tests use capybara-experience with Experiences, Capabilities, and behavior blocks — see `/system-tests` skill for patterns and examples
- Experiences live in `test/support/experiences/`, capabilities in `test/support/capabilities/`
- Use `ApplicationSystemTestCase` for non-JS tests, `JavaScriptSystemTestCase` for JS-dependent tests

### What NOT to Test

- Framework behavior (e.g., don't test that `validates :name, presence: true` rejects `nil` — Rails already tests that)
- Private methods directly — test them through the public interface
- Trivial code with no logic (plain getters, delegations)
- Behavior that only exists in development or test environments (e.g., dev-only seeds, test backdoors, debug endpoints)