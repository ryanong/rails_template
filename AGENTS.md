# Rails Template

_TODO: one-line description of the product._

## Stack

- Ruby 4.0.2, Rails 8.1
- SQLite (storage/ directory)
- ViewComponents
- Tailwind CSS (mobile-first)
- Hotwire (Turbo + Stimulus)
- Sorbet for type checking

## Project Structure

- Views live in `app/views/` as ViewComponents, components in `app/components/`
- Controllers render ViewComponents views directly: `render(ExampleComponent.new(title: "My Title"))`
- `db/schema.rb` has the current database schema
- `packs/` contains packwerk-bounded domain packages — use `bin/rails generate pack NAME` to create one
- `app/policies/` contains authorization policies (one per model)
- `openspec/specs/` contains feature specs that drive test `@spec` traceability tags
- Service objects in `app/services/` use `T::Struct` and are named as verbs — see `/ruby-service-objects` skill for patterns and conventions on how to create or modify them

## Commands

- `bin/rails server` — start dev server
- `bin/rails test` — run tests
- `bin/rubocop` — lint (Rails Omakase style)
- `bin/rails db:migrate` — run migrations
- `bin/brakeman` — security scan
- `bin/bundler-audit` — dependency audit
- `bin/ci` — full CI suite
- `bin/srb tc` - typecheck
- `bin/tapioca dsl` - update sorbet dsl files
- `bin/tapioca gems` — regenerate gem RBI files
- `bin/rails test test/path/to/file_test.rb` — run a single or multiple test files in `test/`
- `bin/rails packs:test` — run tests for all packs
- `bin/rails generate pack NAME` - create new pack with NAME

## Conventions

- `frozen_string_literal: true` in all Ruby files
- Sorbet type signatures all ruby files strict if possible
- use I18n for all user facing strings

### How to use ruby service objects

- `DoSomething.call(named: "arg")` - calls executes the method and returns a `Service::Result[ResultType]`
- `DoSomething.enqueue(named: "arg")` - enqueues the service to be called later via calling `DoSomething::Job.perform_later`
  - > **Gotcha**: Never call `DoSomething::Job.perform_later` directly. Always use `DoSomething.enqueue` instead — it ensures arguments are validated and the service contract is honoured.
- `DoSomething.enqueue_at(time, named: "arg")` - enqueus the service like `enqueue` to be run at a specific time
- `DoSomething.after_call { |result| ... }` - registers a hook that runs after every synchronous `.call`. Accepts either a block or a callable object (but not both). The hook receives the `Service::Result` returned by `#call`.

## Service::Result API

| Method | Use when |
|---|---|
| `Result.success(value)` | Happy path |
| `Result.failure(value, error:)` | Failure — `value` is the unsaved/invalid object, `error` is a `StandardError` |
| `result.ok?` | Check success |
| `result.value!` | Extract value — raises on failure |
| `result.value { \|_v, _e\| default }` | Extract with fallback on failure - block required |
| `result.then { \|v\| Result[U] }` | Chain — block must return another `Result` |
| `result.map { \|v\| plain_value }` | Transform value — block returns plain value, wrapped automatically |
| `result.rescue(ErrClass) { \|v, e\| Result }` | Recover from specific error |
| `result.error` | Returns the `StandardError` or `nil` |

### Frontend Design Philosophy

_TODO: describe this product's UI contexts and design principles. Keep project-specific frontend guidance in a `frontend-design` skill under `.forge/skills/`._

### Coding Style (Pivotal Labs Inspired)

- **Pair-friendly code**: write code that's easy to read and reason about at a glance. Favor clarity over cleverness.
- **Small methods**: each method should do one thing. If you need a comment to explain a block of code, extract it into a well-named method instead.
- **Small classes**: classes should have a single responsibility. When a class grows beyond ~100 lines, look for extraction opportunities.
- **Intention-revealing names**: variable, method, and class names should describe *what* and *why*, not *how*. Avoid abbreviations.
- **Tell, don't ask**: prefer `object.do_thing` over `if object.state? then do_thing_to(object)`. Push behavior into the object that owns the data.
- **Prefer composition over inheritance**: use mixins and delegation rather than deep class hierarchies.
- **No premature abstraction**: wait until you see duplication in 3+ places before extracting. Two similar things are not a pattern.
- **Skinny controllers**: controllers handle HTTP concerns (params, redirects, status codes). Business logic belongs in models or service objects.
- **Models own the data layer**: models own associations, validations, and scopes. Keep them free of orchestration logic.
- **Services own the business and orchestration layer**: use service objects when an action spans multiple models or has complex logic. Name them as verbs: `CreateProject`, `CancelSubscription`. See `/ruby-service-objects` skill for patterns.
- **Fail fast and loud**: raise exceptions for unexpected states rather than silently returning nil. Use guard clauses at the top of methods.
- **Consistent code paths**: avoid `unless` with `else`, double negatives, or negated ternaries. Prefer positive conditionals.
- **Boy Scout Rule**: leave code cleaner than you found it — but only in the area you're already touching. Don't refactor unrelated code in the same change.