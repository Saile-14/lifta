# Shared by the disciplines scored as kilograms lifted times a bodyweight
# coefficient (DOTS, Sinclair).
module Discipline::Barbell
  def weighted?
    true
  end

  def requires_bodyweight?(_weight_kg)
    true
  end

  def weight_label
    "Weight"
  end

  # The weight needed for the next tier at the given bodyweight, rounded up to
  # the next loadable step in the lifter's unit.
  def target(tier, exercise:, bodyweight_kg:, sex:, unit:)
    next_name = tier.next_name
    return unless next_name && bodyweight_kg

    max_kg = scale(exercise, sex).threshold(next_name) / coefficient(bodyweight_kg, sex)
    set_weight_kg = round_up(max_kg / (1 + target_set_reps / 30.0), unit) if target_set_reps

    Discipline::Target.new(tier_name: next_name, weight_kg: round_up(max_kg, unit),
      set_reps: target_set_reps, set_weight_kg: set_weight_kg)
  end

  private
    def round_up(kg, unit)
      step = plate_step.fetch(unit.to_s)
      in_unit = WeightConversion.from_kg(kg, unit)
      WeightConversion.to_kg(((in_unit / step) - 1e-9).ceil * step, unit)
    end
end
