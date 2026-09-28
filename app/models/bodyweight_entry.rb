class BodyweightEntry < ApplicationRecord
  belongs_to :user

  validates :kilograms, presence: true
  validates :kilograms, numericality: { greater_than: 20, less_than: 400, message: :implausible_weight }, allow_nil: true
  validates :recorded_at, presence: true

  before_validation :default_recorded_at, on: :create

  # Lifts snapshot the bodyweight their date resolves to, so any change to
  # the log can change what that is -- a backfilled older weigh-in most of
  # all. Done inline, in the same transaction as the change: it's one
  # lifter's lifts, resolved in memory, and whoever just saved the weigh-in
  # should see their scores already right on the next page.
  after_save :resnapshot_lifts, if: -> { saved_change_to_kilograms? || saved_change_to_recorded_at? }
  # Not when the whole lifter is being deleted: their lifts are going too.
  after_destroy :resnapshot_lifts, unless: :destroyed_by_association
  after_commit :refresh_leaderboards, if: -> { @rescored_lifts.present? }

  private

  def default_recorded_at
    self.recorded_at ||= Time.current
  end

  def resnapshot_lifts
    others = user.bodyweight_entries.where.not(id: id).pluck(:recorded_at, :kilograms)
    now = destroyed? ? others : others + [ [ recorded_at, kilograms ] ]

    @rescored_lifts = user.resnapshot_bodyweight(
      was: BodyweightLog.new(others + previous_weigh_in, time_zone: user.time_zone),
      now: BodyweightLog.new(now, time_zone: user.time_zone)
    )
  end

  # This entry as it stood before this change, if it existed.
  def previous_weigh_in
    if destroyed?
      [ [ recorded_at, kilograms ] ]
    elsif previously_new_record?
      []
    else
      [ [ recorded_at_before_last_save, kilograms_before_last_save ] ]
    end
  end

  # Same split as Lift#refresh_leaderboards: invalidate now, rebuild in a
  # job -- once for however many lifts were rescored.
  def refresh_leaderboards
    @rescored_lifts = nil
    LeaderboardCache.invalidate!
    RefreshLeaderboardsJob.perform_later
  end
end
