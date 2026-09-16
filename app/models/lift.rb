class Lift < ApplicationRecord
  belongs_to :user

  # exercise is a string column. Rails' enum stores integers by default
  # (even with the array form), which get serialized through the string
  # column as text ("0") and then fail to deserialize back to a label
  # (silently reading back as nil) -- so the mapping must use matching
  # string values instead.
  enum :exercise, { squat: "squat", bench: "bench", deadlift: "deadlift" }

  validates :exercise, presence: true
  validates :weight_lifted, numericality: { greater_than: 0 }
  validates :reps, numericality: { only_integer: true, greater_than: 0 }
  validates :bodyweight_kg, presence: true, numericality: { greater_than: 0 }

  before_validation :default_bodyweight_kg, on: :create
  before_validation :default_lifted_at, on: :create

  def estimated_one_rep_max
    return weight_lifted.to_f if reps.to_i <= 1

    weight_lifted.to_f * (1 + reps.to_i / 30.0)
  end

  def dots_score
    @dots_score ||= Dots::Calculator.new(
      weight_lifted: estimated_one_rep_max,
      bodyweight: bodyweight_kg,
      sex: user.sex
    ).call
  end

  def benchmark
    Dots::Tier.for(score: dots_score)
  end

  private

  def default_bodyweight_kg
    self.bodyweight_kg ||= user&.current_bodyweight_kg
  end

  def default_lifted_at
    self.lifted_at ||= Date.current
  end
end
