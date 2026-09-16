# Lifta

Log your sex, bodyweight, and lifts (squat/bench/deadlift). Your rank
(bronze -> grandmaster, top-tier name still WIP) per lift is computed from
your [DOTS score](https://en.wikipedia.org/wiki/DOTS_(formula)) -- a
published, competition-standard formula that normalizes a lift for
bodyweight and sex, so lifters of any size can be compared on the same
ladder. Ranking is fully formula-based; there's no external
strength-standards table to keep up to date.

## Requirements

* Ruby (see `.ruby-version`)
* SQLite3 (bundled via the `sqlite3` gem, no separate server needed)

## Setup

```
bin/setup
```

This installs gems and prepares the development and test databases. Or by
hand:

```
bundle install
bin/rails db:prepare
RAILS_ENV=test bin/rails db:prepare
```

## Running it

```
bin/rails server
```

Then visit http://localhost:3000, sign up, log a bodyweight entry, and log
a lift to see your rank. `bin/rails db:seed` (development only) creates a
demo account: `demo@example.com` / `password123`.

## Testing (TDD via RSpec)

```
bin/rspec
```

The suite covers models (`spec/models`), the DOTS scoring services
(`spec/services`), and full request flows through the controllers
(`spec/requests`). Write the spec first, watch it fail, then implement.

## Linting / security

```
bin/rubocop
bin/brakeman
bin/bundler-audit
```

All three are clean as of the last commit; keep them that way before
merging.

## Architecture notes

* **Auth** uses Rails 8's built-in cookie-session generator (`User`,
  `Session`, `Current`, `Authentication` concern) -- no Devise.
* **Bodyweight is a log, not a profile field** (`BodyweightEntry`), because
  it changes over time and each lift needs the bodyweight *at the time of
  that lift* (like a powerlifting meet weigh-in) for an accurate DOTS
  score, not your current bodyweight.
* **Units**: users pick a display preference (kg or lb) but everything is
  stored canonically in kilograms; conversion happens once, at the
  controller boundary, via `WeightConversion`.
* **`Dots::Calculator`** implements the published DOTS polynomial.
  **`Dots::Tier`** maps a DOTS score, as a percentage of the male/female
  world record (600), onto the bronze -> grandmaster ladder.

## Deployment

This app is set up for [Kamal](https://kamal-deploy.org) (see
`config/deploy.yml` and `.kamal/`) -- deploy anywhere as a single Docker
container with SQLite on a persistent volume, which comfortably handles the
expected scale (~500 users, ~20 concurrent). No separate database server to
provision.

```
bin/kamal setup   # first deploy
bin/kamal deploy  # subsequent deploys
```

You'll need `config/master.key` (not checked into git) available wherever
you run `kamal deploy` from, and a container registry configured in
`config/deploy.yml`.

## Windows-specific notes

* Gems are pinned in `Gemfile` beyond Rails' defaults where needed for this
  environment -- e.g. `json` is pinned to `~> 2.9` because `json` 3.0.2
  breaks reading signed cookies (including the session cookie) under
  ActiveSupport 8.1.3.1. If `bundle install` ever drifts `json` back to
  3.x, re-pin it.
* You may see `VIPS-WARNING` lines about missing `.dll` plugins on any
  `bin/rails` command. That's `libvips` (via the `image_processing` gem,
  used for Active Storage image variants) probing for optional codec
  plugins this install doesn't have. It's harmless noise, not an error --
  ignore it.
