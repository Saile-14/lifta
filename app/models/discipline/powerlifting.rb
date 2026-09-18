class Discipline::Powerlifting < Discipline
  include Discipline::Barbell

  # DOTS points for roughly a world-class single lift. Each sex's three add up
  # to 600, a world-class DOTS total, which the overall rank is measured
  # against. Tune freely: lifts store their DOTS score, not their tier.
  CEILINGS = {
    "squat"    => { male: 215, female: 210 },
    "bench"    => { male: 155, female: 135 },
    "deadlift" => { male: 230, female: 255 }
  }.freeze

  def key
    "powerlifting"
  end

  def exercises
    [ Exercise.new("squat"), Exercise.new("bench"), Exercise.new("deadlift") ]
  end

  # Past ~10 reps a 1RM estimate stops meaning much.
  def max_reps
    10
  end

  def score(weight_kg:, reps:, bodyweight_kg:, sex:, **)
    Dots::Calculator.new(weight_lifted: estimated_max(weight_kg, reps), bodyweight: bodyweight_kg, sex: sex).call
  end

  def scale(exercise, sex)
    Scale.linear(CEILINGS.fetch(exercise.to_s).fetch(sex.to_sym))
  end

  def coefficient(bodyweight_kg, sex)
    Dots::Calculator.coefficient(bodyweight: bodyweight_kg, sex: sex)
  end

  def plate_step
    { "kg" => 2.5, "lb" => 5.0 }
  end

  # Targets also offer a set of 5, since most people don't test singles.
  def target_set_reps
    5
  end
end
