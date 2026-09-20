class Lift < ApplicationRecord
  belongs_to :user

  # exercise is a string column. Rails' enum stores integers by default
  # (even with the array form), which get serialized through the string
  # column as text ("0") and then fail to deserialize back to a label
  # (silently reading back as nil) -- so the mapping must use matching
  # string values instead.
  enum :exercise, Discipline.exercise_keys.index_with(&:itself)

  # Diamond-and-above lifts wait for an admin to approve them. Only approved
  # lifts count toward ranks and leaderboards.
  enum :status, { approved: "approved", pending: "pending", rejected: "rejected" }, default: :approved

  scope :in_discipline, ->(discipline) { where(exercise: discipline.exercise_keys) }
  scope :recent_first, -> { order(lifted_at: :desc, created_at: :desc) }

  validates :exercise, presence: true
  validates :weight_lifted, presence: true, if: :weighted?
  validates :weight_lifted, numericality: { greater_than: 0 }, allow_nil: true, if: :weighted?
  validates :weight_lifted, numericality: { greater_than_or_equal_to: 0 }, unless: :weighted?
  validates :reps, numericality: { only_integer: true, greater_than: 0 }
  validates :bodyweight_kg, presence: { message: :needed_to_score }, if: :requires_bodyweight?
  validates :bodyweight_kg, numericality: { greater_than: 20, less_than: 400, message: :implausible_weight }, allow_nil: true
  validate :reps_within_discipline_limit
  validate :lifted_at_not_in_future
  validate :score_is_plausible

  # Order matters: the bodyweight snapshot is looked up for the lift's date.
  before_validation :default_lifted_at, :default_bodyweight_kg
  before_validation :default_added_weight, :compute_score
  before_save :review, if: -> { score && (new_record? || will_save_change_to_score?) }

  # Any lift can move a board: a new best changes a rank, and an approval or
  # rejection changes whether it counts at all.
  after_commit :refresh_leaderboards

  def discipline
    Discipline.for_exercise(exercise) if exercise
  end

  def exercise_name
    discipline.exercise(exercise).name
  end

  def tier
    discipline.tier_for(score, exercise: exercise, sex: user.sex) if score
  end

  # Only meaningful for barbell lifts; calisthenics scores in reps.
  def estimated_one_rep_max
    discipline.estimated_max(weight_lifted, reps) if discipline.weighted?
  end

  # Recomputes the stored score, e.g. after a formula change, re-reviewing the
  # lift if its score moved.
  def rescore!
    compute_score
    save!(validate: false)
  end

  private
    # Invalidate now (one cache write, so nobody reads a stale board), and
    # let a job do the rebuilding.
    def refresh_leaderboards
      LeaderboardCache.invalidate!
      RefreshLeaderboardsJob.perform_later
    end

    def weighted?
      discipline.nil? || discipline.weighted?
    end

    def requires_bodyweight?
      discipline&.requires_bodyweight?(weight_lifted)
    end

    def default_lifted_at
      self.lifted_at ||= user&.today || Date.current
    end

    def default_bodyweight_kg
      self.bodyweight_kg ||= user&.bodyweight_on(lifted_at)
    end

    def default_added_weight
      self.weight_lifted ||= 0 unless weighted?
    end

    def compute_score
      return unless scorable?

      self.score = discipline.score(weight_kg: weight_lifted, reps: reps.to_i, bodyweight_kg: bodyweight_kg,
        sex: user.sex, exercise: exercise)
    end

    def scorable?
      user && discipline && weight_lifted && reps.to_i.positive? &&
        (!requires_bodyweight? || bodyweight_kg.to_f.positive?)
    end

    def review
      self.status = tier.needs_review? ? :pending : :approved
    end

    def reps_within_discipline_limit
      return unless discipline && reps.to_i > discipline.max_reps

      errors.add(:reps, discipline.weighted? ? :too_many_to_estimate : :too_many,
        count: discipline.max_reps, discipline: discipline.name.downcase)
    end

    def lifted_at_not_in_future
      errors.add(:lifted_at, :in_future) if lifted_at && user && lifted_at > user.today
    end

    def score_is_plausible
      return unless score && tier.implausible?

      errors.add(:base, :implausible)
    end
end
