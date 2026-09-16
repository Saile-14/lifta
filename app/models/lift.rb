class Lift < ApplicationRecord
  belongs_to :user

  enum :exercise, { squat: 0, bench: 1, deadlift: 2 }

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

  def benchmark
    score = Dots::Calculator.new(
      weight_lifted: estimated_one_rep_max,
      bodyweight: bodyweight_kg,
      sex: user.sex
    ).call
    Dots::Tier.for(score: score)
  end

  private

  def default_bodyweight_kg
    self.bodyweight_kg ||= user&.current_bodyweight_kg
  end

  def default_lifted_at
    self.lifted_at ||= Date.current
  end
end
