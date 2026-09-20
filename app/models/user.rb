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

  def current_bodyweight_kg
    bodyweight_entries.order(recorded_at: :desc).pick(:kilograms)
  end

  # Bodyweight as of the end of that day -- the latest weigh-in on or before
  # it, like a meet weigh-in -- falling back to the first one logged after.
  def bodyweight_on(date)
    return current_bodyweight_kg unless date

    day_end = date.to_date.in_time_zone(time_zone).end_of_day
    bodyweight_entries.where(recorded_at: ..day_end).order(recorded_at: :desc).pick(:kilograms) ||
      bodyweight_entries.order(:recorded_at).pick(:kilograms)
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
    def time_zone_exists
      errors.add(:time_zone, :unknown_time_zone) unless ActiveSupport::TimeZone[time_zone.to_s]
    end
end
