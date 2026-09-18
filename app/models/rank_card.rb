# A lifter's standing in one discipline: their best approved lift and tier
# per exercise, what the next tier takes, and the overall rank once every
# exercise has a lift.
class RankCard
  Row = Data.define(:exercise, :lift, :tier, :target)

  attr_reader :user, :discipline

  def initialize(user, discipline)
    @user = user
    @discipline = discipline
  end

  def rows
    @rows ||= discipline.exercises.map do |exercise|
      lift = user.best_lift(exercise.key)
      tier = lift&.tier
      Row.new(exercise: exercise, lift: lift, tier: tier, target: tier && target_for(exercise, tier, lift))
    end
  end

  def overall
    percent = discipline.overall_percent(scores, user.sex)
    Tier.new(percent) if percent
  end

  # The DOTS or Sinclair total, for disciplines where a total means something.
  def total_score
    scores.values.sum if complete? && discipline.weighted?
  end

  def complete?
    rows.all?(&:lift)
  end

  def ranked?
    rows.any?(&:lift)
  end

  private
    def scores
      rows.select(&:lift).to_h { |row| [ row.exercise.key, row.lift.score ] }
    end

    # Targets assume the lifter stays at their current bodyweight.
    def target_for(exercise, tier, lift)
      @bodyweight_kg ||= user.current_bodyweight_kg || lift.bodyweight_kg
      discipline.target(tier, exercise: exercise.key, bodyweight_kg: @bodyweight_kg, sex: user.sex, unit: user.weight_unit)
    end
end
