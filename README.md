# Rails Template

Starter for greenfield Rails apps: Rails 8.1, SQLite, Solid Queue/Cache/Cable, ViewComponents, Tailwind, Hotwire, Sorbet, Packwerk packs, Action Policy, and `Service` objects returning `Service::Result`.

## Starting a new app

```sh
cp -R ~/workspace/rails_template ~/workspace/my_new_app
cd ~/workspace/my_new_app
rm -rf .git && git init && git add -A
bin/rename-app MyNewApp
bin/setup --skip-server
bin/ci
```

Then fill in the `TODO`s in `AGENTS.md` (symlinked as `CLAUDE.md`) and `openspec/config.yaml`.

## What's included

- `app/services/service.rb` — `Service` concern: `.call`, `.enqueue`, `.enqueue_at`, `.after_call`, policy-backed `authorize!`
- `lib/generators/pack` — `bin/rails generate pack NAME` creates a packwerk pack with its own engine
- Importmap and Tailwind auto-discover pack JavaScript, views, and components
- `sorbet/tapioca/compilers` — DSL compilers for `Service` and `Capybara::Experience`
- `test/support` — Capybara Experience system-test harness (rack_test and Cuprite drivers)
- `.forge/skills` (symlinked as `.claude/skills`) — service objects, testing, system tests, OpenSpec workflow
- `templates/` — epic and story templates for XP planning

## Not included (add per project)

- Authentication and a `User` model. `Current.user`, `ApplicationController#current_user`, and `Service#actor` are wired but typed `T.untyped` until a `User` exists.
- Layouts, home page, and frontend design guidance
- Production credentials (`bin/rails credentials:edit --environment production`)
