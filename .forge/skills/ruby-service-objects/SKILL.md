---
name: ruby-service-objects
description: Use when writing or modifying a Ruby service class in this codebase. Covers class structure, Sorbet types, Service::Result success/failure, authorization, custom errors, service composition, and Minitest testing patterns.
---

# Ruby Service Objects

Services are `T::Struct` subclasses that `include Service`. Never call `new` directly — use `.call` or `.enqueue`.

## Skeleton

```ruby
# typed: strict
# frozen_string_literal: true

class DoSomething < T::Struct
  include Service

  CustomError = Class.new(Error)  # inherits auto-generated Error < StandardError
  ValidationError = Class.new(Error) # for validation failures, if needed

  const :actor, User              # required, immutable
  const :event, Event
  prop  :count, Integer, default: 0  # optional with default

  sig { returns(Result[Rsvp]) }
  def call
    authorize!(@event)            # raises ActionPolicy::Unauthorized on failure
    rsvp = Rsvp.new(event: @event, user: @actor)

    return Result.failure(Rsvp.new, error: CustomError.new(t("key"))) unless custom_condition?(rsvp)

    if rsvp.save
      Result.success(rsvp)
    else
      Result.failure(rsvp, error: ValidationError.new)
    end
  end

  private

  sig { returns(T::Boolean) }
  def custom_condition?(rsvp)
    # private helpers need sig
  end
end
```

## `const` vs `prop`

| | `const` | `prop` |
|---|---|---|
| Required? | Yes | No (needs `default:`) |
| Mutable? | No | Yes (`.=` allowed) |

## Return types

| Situation | Sig |
|---|---|
| Always returns one type | `Result[Rsvp]` |
| Nullable value | `Result[T.nilable(Rsvp)]` |
| Two possible value types | `T.any(Result[Rsvp], Result[SmsInvitation])` |

## Authorization

```ruby
authorize!(@event)                       # calls event_policy#do_something? (derived from class name)
authorize!(@event, with: RsvpPolicy)     # explicit policy class
authorize!(@event, to: :update_profile?) # explicit action
```

Raises `ActionPolicy::Unauthorized` — never returns false. Tests assert with `assert_raises`.

## Custom errors

Prefer `Class.new(Error)` to extend the auto-generated service-level `Error`:

```ruby
DuplicateError = Class.new(Error)
NotReadyError  = Class.new(Error)
```

Use bare `Class.new(StandardError)` only when the error must be catchable outside the service.

## Idempotency

If a service needs to be idempotent define the `runnable?` method to return false when the action has already been performed:

```ruby
sig { returns(T::Boolean) }
def runnable?
  !Rsvp.exists?(event: @event, user: @actor)
end
```

## Service composition & async

```ruby
# Synchronous composition
inner = OtherService.call(param: value)
return inner unless inner.ok?

# Async (auto-generated Job class)
OtherService.enqueue(param: value)
```

## Example — `InviteGuest` (service + test)

```ruby
# typed: strict
# frozen_string_literal: true

class InviteGuest < T::Struct
  include Service

  DuplicateError  = Class.new(Error)
  ValidationError = Class.new(Error)

  const :actor, User
  const :event, Event
  const :invitee, User

  sig { returns(Result[Rsvp]) }
  def call
    authorize!(@event)

    rsvp = Rsvp.new(event: @event, user: @invitee, status: :invited, invited_by: @actor)

    unless rsvp.save
      return Result.failure(
        rsvp,
        error: rsvp.errors.where(:user_id, :taken).any? ? DuplicateError.new : ValidationError.new
      )
    end

    Result.success(rsvp)
  end
end
```

```ruby
# typed: false
# frozen_string_literal: true

# @spec guest-invitations
require "test_helper"

class InviteGuestTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @host    = users(:maya)
    @invitee = users(:other)
    @event   = events(:published_event)
    @event.update_columns(guests_can_invite: false)
  end

  test "host invites user — creates invited RSVP" do
    result = InviteGuest.call(actor: @host, event: @event, invitee: @invitee)

    assert result.ok?
    rsvp = result.value!
    assert_equal "invited", rsvp.status
    assert_equal @host.id, rsvp.invited_by_id
  end

  test "raises Unauthorized when actor cannot invite" do
    guest = users(:third)
    Rsvp.create!(event: @event, user: guest, status: :going)

    assert_raises(ActionPolicy::Unauthorized) do
      InviteGuest.call(actor: guest, event: @event, invitee: @invitee)
    end
  end

  test "returns DuplicateError when invitee already has an RSVP" do
    Rsvp.create!(event: @event, user: @invitee, status: :going)

    result = InviteGuest.call(actor: @host, event: @event, invitee: @invitee)

    assert_not result.ok?
    assert_kind_of InviteGuest::DuplicateError, result.error
  end
end
```

## Quick reference

| Question | Answer |
|---|---|
| Required param type | `const` |
| Optional param type | `prop` with `default:` |
| Test authorization failure | `assert_raises(ActionPolicy::Unauthorized)` |
| Test custom error type | `assert_kind_of ServiceName::ErrorClass, result.error` |
| `then` vs `map`? | `then` when block returns a `Result`; `map` when block returns a plain value |
| `value!` vs `value {}`? | `value!` raises on failure; `value { fallback }` returns fallback |
| Where does `t("key")` look? | `services.<service_name_underscore>.<key>` in i18n files |
| Include `ActiveJob::TestHelper`? | Only when asserting `assert_enqueued_with` |
| Test file `# typed:` pragma | Always `# typed: false` |
| Service file `# typed:` pragma | Always `# typed: strict` |
