class Discipline::Weightlifting < Discipline
  include Discipline::Barbell

  # Sinclair points for roughly a world-class snatch and clean & jerk. Each
  # sex's pair adds up to a world-class Sinclair total (470 men, 340 women),
  # which the overall rank is measured against. Unlike DOTS, Sinclair doesn't
  # equalise the sexes, hence the separate ceilings.
  CEILINGS = {
    "snatch"         => { male: 210, female: 150 },
    "clean_and_jerk" => { male: 260, female: 190 }
  }.freeze

  def key
    "weightlifting"
  end

  def exercises
    [ Exercise.new("snatch"), Exercise.new("clean_and_jerk") ]
  end

  # The Olympic lifts are technique-limited; only near-max sets say much
  # about a max.
  def max_reps
    3
  end

  def score(weight_kg:, reps:, bodyweight_kg:, sex:, **)
    Sinclair::Calculator.new(weight_lifted: estimated_max(weight_kg, reps), bodyweight: bodyweight_kg, sex: sex).call
  end

  def scale(exercise, sex)
    Scale.linear(CEILINGS.fetch(exercise.to_s).fetch(sex.to_sym))
  end

  def coefficient(bodyweight_kg, sex)
    Sinclair::Calculator.coefficient(bodyweight: bodyweight_kg, sex: sex)
  end

  def plate_step
    { "kg" => 1.0, "lb" => 2.0 }
  end

  def target_set_reps
    nil
  end
end
