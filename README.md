*English / [日本語](README.ja.md)*

# Lifta

Log your lifts and see how each one ranks against a world-class standard for
your bodyweight and sex, on a bronze -> silver -> gold -> platinum -> diamond
-> grandmaster ladder. Three disciplines, each with its own tab and ranks:

* **Powerlifting** (squat, bench, deadlift), scored with DOTS.
* **Weightlifting** (snatch, clean & jerk), scored with the
  [Sinclair coefficient](https://en.wikipedia.org/wiki/Sinclair_coefficient).
* **Calisthenics** (pull-ups, dips, push-ups), scored on strict reps, with
  added weight credited as extra reps.

On top of those, a **combined rank** averages your progress through all
three disciplines, on its own ladder: dormant, awakened, evolved, apex,
transcendent, **Ultimate Lifeform**. A discipline you've never trained
counts as zero, so a pure powerlifter tops out around a third of the way
up -- the combined ladder rewards breadth, and its top rung means
world-class in all three at once. Lifters choose which of their four ranks
to show as badges beside their name.

Every lift gets its own rank, and each discipline gets an overall rank once
every lift in it is logged. The dashboard shows what the next tier takes
("Next: Gold at 187.5 kg, or 162.5 kg x 5"). Lifters who opt in get a public
profile and a place on the leaderboard. Diamond-and-above lifts wait for an
admin to approve them before they count.

The whole app is in **English and Japanese (日本語)**, with a language button
in the header.

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

Then visit http://localhost:3000. `bin/rails db:seed` (development only)
creates demo accounts, all with password `password123`:

* `demo@example.com`: a lifter with lifts in all three disciplines
* `admin@example.com`: an admin, with a lift waiting in the review queue
* a handful of listed lifters, so the leaderboard has people on it

## Admins

Make an existing account an admin (or take it away):

```
bin/rails "admin:grant[you@example.com]"
bin/rails "admin:revoke[you@example.com]"
```

In production, run it inside the app container:

```
bin/kamal app exec --reuse 'bin/rails "admin:grant[you@example.com]"'
```

Admins get an **Admin** link in the nav, with the number of lifts waiting for
review:

* **Review queue**: lifts that rank diamond or above. Approve them (they then
  count toward ranks and the leaderboard), reject them (they stay in the
  lifter's history, marked rejected), or delete them.
* **Users**: search accounts, see anyone's lifts, delete a lift, or delete a
  user along with their lifts, bodyweight log and sessions.

Admin pages 404 for everyone else.

## Testing (TDD via RSpec)

```
bin/rspec
```

The suite covers models (`spec/models`), the scoring formulas
(`spec/services`), full request flows through the controllers
(`spec/requests`) and the rake tasks (`spec/tasks`). Write the spec first,
watch it fail, then implement.

## Linting / security

```
bin/rubocop
bin/brakeman
bin/bundler-audit
```

All three are clean as of the last commit; keep them that way before
merging.

## How scoring works

Everything lives in `app/models/discipline` plus `Tier` and `Scale`:

* **A lift's score is formula-based and stored** (`lifts.score`): DOTS points,
  Sinclair points, or bodyweight-equivalent reps. Sets of more than one rep
  count via an Epley-estimated one-rep max. That estimate stops being reliable
  on long sets, so powerlifting takes up to 10 reps and weightlifting up to 3.
* **A per-sex Scale turns a score into a percentage** of the world-class
  standard for that lift, and the percentage into a `Tier` (bronze from 0%,
  silver 40%, gold 60%, platinum 75%, diamond 90%, grandmaster 100%).
  * Powerlifting and weightlifting use one "ceiling" per lift and sex
    (`CEILINGS`). The powerlifting ceilings add up to a 600-point DOTS total,
    so being X% of the way on every lift puts you X% of the way overall.
  * Calisthenics has no published formula, so it uses explicit rep
    thresholds per tier (`THRESHOLDS`).

  These numbers are rough calibrations, so tune them freely. Tiers aren't
  stored, so changing a ceiling needs no migration.
* **Overall rank**: for powerlifting and weightlifting, the total of your best
  lifts against the total of the ceilings, like a meet total. For
  calisthenics, the average of the per-exercise percentages.
* **Combined rank** (`ComboCard`, `ComboTier`): the average of
  `Discipline#progress_percent` across all three, which counts an exercise
  with no lift as zero rather than leaving the discipline unranked. Its
  rungs sit lower than `Tier`'s (15/30/50/70/90) because averaging makes
  high numbers much harder to reach; the top still needs diamond-level
  strength in all three at once. `RankLadder` holds what the two ladders
  share.
* **Plausibility**: diamond-and-above lifts are held for review. Lifts past
  200% of world class (typos, kg/lb mix-ups) are rejected outright.
* **If you change a formula** (not just a ceiling), recompute the stored
  scores with `bin/rails lifts:rescore`.

The Sinclair constants are the 2021-2024 Olympic-cycle ones. The IWF hasn't
published 2025-2028 values yet, pending the new weight classes. DOTS clamps
bodyweight to its published bounds (40-210 kg men, 40-150 kg women).

## Languages (English / 日本語)

Every user-facing string lives in `config/locales/en.yml` and
`config/locales/ja.yml`. That covers views, flash messages, validation
errors, rank-up messages and dates. Rails' own messages come from the
`rails-i18n` gem.

* **Which language a visitor sees** (the `Localization` concern) is decided
  in this order:
  1. a `?locale=` link, either the header button or a shared link
  2. the language they picked before, remembered in a cookie
  3. their browser's `Accept-Language`
  4. English
* **The language button** names the other language in that language
  ("日本語" / "English") and keeps the current page and filters.
* **Search engines and link previews:** each page links its other-language
  version with `hreflang`. Profile share links carry the sharer's language,
  so link previews (LINE, X, Slack) come out in it.
* **Japanese typography:** a kana/kanji font stack, a little more line
  height, and `word-break: auto-phrase` so lines break between phrases
  rather than mid-word.

**Adding or changing text:** add the key to *both* files. Missing
translations raise in development and test. `spec/i18n_spec.rb` fails if
the two files' keys or `%{placeholders}` drift apart.
`spec/requests/localization_spec.rb` renders every page in Japanese. In
views, use lazy lookups: `t(".title")` in `lifts/index` reads
`lifts.index.title`.

## Design decisions

The reasoning behind the bigger choices — SQLite over PostgreSQL, Rails'
built-in auth over Devise, bodyweight as a log, the accessibility target,
bilingual from the start, how scoring is stored, what the combined rank
means — is recorded in [`docs/adr/`](docs/adr/README.md), in English and
Japanese.

## Architecture notes

* **Auth** uses Rails 8's built-in cookie-session generator (`User`,
  `Session`, `Current`, `Authentication` concern). There's no Devise.
* **Bodyweight is a log, not a profile field** (`BodyweightEntry`), because it
  changes over time. Each lift snapshots the bodyweight *as of the lift's
  date* (like a meet weigh-in), so backdated lifts are scored at the
  bodyweight you had back then. The lift form also takes a bodyweight
  directly, which is added to the log too.
* **Units**: users pick a display preference (kg or lb), but everything is
  stored canonically in kilograms. Conversion happens once, at the controller
  boundary, via `WeightConversion`.
* **Time zones**: each user has one, detected from the browser at sign-up and
  editable in settings. Requests run in it, so "today" on a new lift is the
  lifter's today.
* **Leaderboard and profiles** only include lifters who opted in (ticked by
  default at sign-up, changeable in settings), and only approved lifts. Men
  and women share one board, ordered by progress toward their own sex's
  standard. Public pages never show email or bodyweight.
* **Password resets** are switched off (and the link hidden) until production
  has outgoing mail. Configure SMTP in `config/environments/production.rb`,
  then set `config.x.password_resets_enabled = true` in
  `config/application.rb`.

## Deployment

This app is set up for [Kamal](https://kamal-deploy.org) (see
`config/deploy.yml` and `.kamal/`). Deploy anywhere as a single Docker
container with SQLite on a persistent volume, which comfortably handles the
expected scale (~500 users, ~20 concurrent). There's no separate database
server to provision.

```
bin/kamal setup   # first deploy
bin/kamal deploy  # subsequent deploys
```

You'll need `config/master.key` (not checked into git) available wherever
you run `kamal deploy` from, and a container registry configured in
`config/deploy.yml`.

## Windows-specific notes

* Gems are pinned in `Gemfile` beyond Rails' defaults where needed for this
  environment. For example, `json` is pinned to `~> 2.9` because `json` 3.0.2
  breaks reading signed cookies (including the session cookie) under
  ActiveSupport 8.1.3.1. If `bundle install` ever drifts `json` back to 3.x,
  re-pin it.
* You may see `VIPS-WARNING` lines about missing `.dll` plugins on any
  `bin/rails` command. That's `libvips` (via the `image_processing` gem, used
  for Active Storage image variants) probing for optional codec plugins this
  install doesn't have. It's harmless noise, not an error, so ignore it.

## Licence

MIT. See [LICENSE](LICENSE).
