class Discipline::Calisthenics < Discipline
  # Strict reps needed for silver, gold, platinum, diamond and grandmaster.
  # There's no published formula for calisthenics, so this is a rough
  # ladder: tune freely.
  THRESHOLDS = {
    "pull_up" => { male: [ 8, 15, 22, 30, 40 ],   female: [ 3, 7, 12, 18, 25 ] },
    "dip"     => { male: [ 12, 22, 32, 42, 55 ],  female: [ 5, 12, 20, 28, 35 ] },
    "push_up" => { male: [ 30, 45, 60, 80, 100 ], female: [ 15, 25, 38, 50, 65 ] }
  }.freeze

  # Share of bodyweight each movement actually moves, to credit added weight
  # (belt, vest) fairly.
  BODYWEIGHT_SHARE = { "pull_up" => 1.0, "dip" => 1.0, "push_up" => 0.64 }.freeze

  def key
    "calisthenics"
  end

  def exercises
    [ Exercise.new("pull_up"), Exercise.new("dip"), Exercise.new("push_up") ]
  end

  def max_reps
    300
  end

  def weighted?
    false
  end

  # Bodyweight only matters for converting added weight into reps.
  def requires_bodyweight?(weight_kg)
    weight_kg.to_f.positive?
  end

  def weight_label
    "Added weight"
  end

  # Bodyweight-equivalent reps: plain reps, plus credit for added weight via
  # Epley -- (1 + added/load) x (1 + reps/30) = 1 + score/30, where load is
  # the share of bodyweight the movement moves.
  def score(weight_kg:, reps:, bodyweight_kg:, exercise:, **)
    added = weight_kg.to_f
    return reps.to_f if added.zero?

    (reps + added / (BODYWEIGHT_SHARE.fetch(exercise.to_s) * bodyweight_kg.to_f) * (30 + reps)).round(2)
  end

  def scale(exercise, sex)
    Scale.new(Tier::NAMES.drop(1).zip(THRESHOLDS.fetch(exercise.to_s).fetch(sex.to_sym)).to_h)
  end

  # Reps aren't comparable across movements (50 push-ups vs 50 pull-ups), so
  # the overall rank is the average of the per-exercise percentages instead of
  # a total.
  def overall_percent(scores, sex)
    return unless complete?(scores)

    exercise_keys.sum { |key| scale(key, sex).percent_for(scores[key]) } / exercise_keys.size
  end

  def target(tier, exercise:, sex:, **)
    next_name = tier.next_name
    return unless next_name

    Discipline::Target.new(tier_name: next_name, reps: scale(exercise, sex).threshold(next_name).ceil)
  end
end
