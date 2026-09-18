class User < ApplicationRecord
  RESERVED_USERNAMES = %w[ admin administrator lifta moderator root staff support ].freeze

  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :bodyweight_entries, dependent: :destroy
  has_many :lifts, dependent: :destroy

  enum :sex, { male: 0, female: 1 }
  enum :weight_unit, { kg: 0, lb: 1 }, default: :kg

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :username, with: ->(u) { u.strip.downcase.delete_prefix("@") }

  validates :email_address, presence: true, uniqueness: true
  validates :sex, presence: true
  validates :username, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9_]{3,20}\z/, message: "must be 3-20 letters, numbers or underscores" },
    exclusion: { in: RESERVED_USERNAMES, message: "is reserved" }
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

  def today
    Time.current.in_time_zone(time_zone).to_date
  end

  def best_lift(exercise)
    lifts.approved.where(exercise: exercise).order(score: :desc, lifted_at: :asc).first
  end

  def rank_for(exercise)
    best_lift(exercise)&.tier
  end

  private
    def time_zone_exists
      errors.add(:time_zone, "isn't a known time zone") unless ActiveSupport::TimeZone[time_zone.to_s]
    end
end
