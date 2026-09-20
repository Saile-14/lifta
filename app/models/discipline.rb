# A sport with its own lifts, scoring formula and rank ladder: powerlifting
# (DOTS), weightlifting (Sinclair) and calisthenics (reps). Every lift gets a
# formula-based score, and a per-sex Scale turns that score into a Tier.
class Discipline
  Exercise = Data.define(:key) do
    def name
      I18n.t("exercises.#{key}")
    end
  end

  # What it takes to reach the next tier on one exercise. Barbell disciplines
  # fill in weights (kg, rounded up to something loadable), calisthenics fills
  # in reps.
  Target = Data.define(:tier_name, :weight_kg, :set_reps, :set_weight_kg, :reps) do
    def initialize(tier_name:, weight_kg: nil, set_reps: nil, set_weight_kg: nil, reps: nil)
      super
    end
  end

  class << self
    def all
      @all ||= [ Powerlifting.new, Weightlifting.new, Calisthenics.new ].freeze
    end

    def find(key)
      all.find { |discipline| discipline.key == key.to_s }
    end

    def default
      all.first
    end

    def for_exercise(exercise)
      all.find { |discipline| discipline.exercise?(exercise) }
    end

    def exercise_keys
      all.flat_map(&:exercise_keys)
    end
  end

  def name
    I18n.t("disciplines.#{key}")
  end

  def exercise_keys
    exercises.map(&:key)
  end

  def exercise?(key)
    exercise_keys.include?(key.to_s)
  end

  def exercise(key)
    exercises.find { |exercise| exercise.key == key.to_s }
  end

  def to_param
    key
  end

  # Epley estimate; a single is taken as-is.
  def estimated_max(weight_kg, reps)
    reps.to_i <= 1 ? weight_kg.to_f : weight_kg.to_f * (1 + reps.to_i / 30.0)
  end

  def tier_for(score, exercise:, sex:)
    scale(exercise, sex).tier_for(score)
  end

  # The discipline-wide rank, once every exercise has a score. Held back
  # until then so a lifter isn't shown an overall rank dragged down by lifts
  # they simply haven't logged yet.
  def overall_percent(scores, sex)
    progress_percent(scores, sex) if complete?(scores)
  end

  # Like overall_percent, but an exercise with no score counts as zero
  # instead of leaving the discipline unranked. Like a meet total, it's the
  # sum of the scores against the sum of their ceilings, so being X% of the
  # way on every lift puts you X% of the way overall. The combined rank uses
  # this, since it needs a number for every discipline including untouched
  # ones.
  def progress_percent(scores, sex)
    100.0 * exercise_keys.sum { |key| scores[key].to_f } / exercise_keys.sum { |key| scale(key, sex).ceiling }
  end

  def complete?(scores)
    exercise_keys.all? { |key| scores[key] }
  end
end
