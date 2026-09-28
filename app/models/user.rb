class User < ApplicationRecord
  RESERVED_USERNAMES = %w[ admin administrator lifta moderator root staff support ].freeze

  # Ranks a lifter can show off next to their name: the combined one, plus
  # one per discipline.
  BADGES = [ ComboCard::KEY, *Discipline.all.map(&:key) ].freeze

  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :bodyweight_entries, dependent: :destroy
  has_many :lifts, dependent: :destroy

  enum :sex, { male: 0, female: 1 }
  enum :weight_unit, { kg: 0, lb: 1 }, default: :kg

  # NFKC first, so a username or address typed on a Japanese IME ("ｄｅｍｏ",
  # "ｔａｒｏ＠ｅｘａｍｐｌｅ.ｃｏｍ") folds to ASCII instead of failing the
  # format check. See WidthNormalization.
  normalizes :email_address, with: ->(e) { WidthNormalization.normalize(e).strip.downcase }
  normalizes :username, with: ->(u) { WidthNormalization.normalize(u).strip.downcase.delete_prefix("@") }

  validates :email_address, presence: true, uniqueness: true
  validates :sex, presence: true
  validates :username, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9_]{3,20}\z/, message: :invalid_username },
    exclusion: { in: RESERVED_USERNAMES, message: :reserved }
  validate :time_zone_exists

  # Users who opted in to the leaderboard and a public profile page.
  scope :listed, -> { where(public_profile: true) }

  # Opting in or out changes who is on a board; sex changes which standard
  # they're measured against; username is the tie-break when two lifters sit
  # at the same percentage.
  after_commit :refresh_leaderboards, if: :leaderboard_relevant_change?

  def current_bodyweight_kg
    bodyweight_entries.order(recorded_at: :desc).pick(:kilograms)
  end

  # Bodyweight as of the end of that day -- the latest weigh-in on or before
  # it, like a meet weigh-in -- falling back to the first one logged after.
  def bodyweight_on(date)
    BodyweightLog.for(self).on(date)
  end

  # Called when a weigh-in is logged, corrected or deleted (see
  # BodyweightEntry), with the log as it was and as it is now. Each lift
  # snapshots the bodyweight its date resolved to, so a change to the log can
  # leave a lift scored at a weight the log no longer says -- most often a
  # lift from before the first weigh-in, snapshotted at the fallback, when an
  # older weigh-in is backfilled.
  #
  # Only lifts whose date now resolves differently are touched, and only if
  # they still carry the old resolved weight; one that doesn't had its own
  # bodyweight typed in, and keeps it. Emptying the log touches nothing:
  # better the last known weight than none to score at.
  #
  # Returns the lifts it rescored. Their leaderboard refresh is left to the
  # caller, to do once for the lot.
  def resnapshot_bodyweight(was:, now:)
    # A relation, not the association itself: loading the association would
    # cache it on this user, and a later `destroy` would then see that list.
    lifts.order(:lifted_at).filter_map do |lift|
      before, after = was.on(lift.lifted_at), now.on(lift.lifted_at)
      next unless after && after != before && lift.bodyweight_kg == before

      lift.bodyweight_kg = after
      lift.skip_leaderboard_refresh = true
      lift.rescore!
      lift
    end
  end

  # Logs a weigh-in for the day of a lift, unless that day already has one.
  def record_weigh_in(kilograms, on:)
    day = on.in_time_zone(time_zone).all_day
    return if bodyweight_entries.exists?(recorded_at: day)

    bodyweight_entries.create(kilograms: kilograms, recorded_at: on == today ? Time.current : day.first.change(hour: 12))
  end

  def today
    Time.current.in_time_zone(time_zone).to_date
  end

  def best_lift(exercise)
    lifts.approved.where(exercise: exercise).order(score: :desc, lifted_at: :asc).first
  end

  def rank_for(exercise)
    best_lift(exercise)&.tier
  end

  # Kept to BADGES and in its order, so an unknown key can't be stored and
  # the badges always read combined-first regardless of tick order. The
  # checkbox form submits a blank entry to mean "none", which drops out here.
  def featured_badges=(badges)
    super(BADGES & Array(badges).map(&:to_s))
  end

  def features_badge?(badge)
    featured_badges.include?(badge.to_s)
  end

  private
    def leaderboard_relevant_change?
      destroyed? || saved_change_to_public_profile? || saved_change_to_sex? || saved_change_to_username?
    end

    def refresh_leaderboards
      LeaderboardCache.invalidate!
      RefreshLeaderboardsJob.perform_later
    end

    def time_zone_exists
      errors.add(:time_zone, :unknown_time_zone) unless ActiveSupport::TimeZone[time_zone.to_s]
    end
end
