module ProgressHelper
  # A charted value with its unit, for sentences: "142.5 kg", "17.5 reps".
  # Progress has already converted weights into the viewer's unit.
  def progress_value(value, reps: false)
    if reps
      t("scores.calisthenics", score: chart_number(value), count: value)
    else
      "#{chart_number(value)} #{weight_unit}"
    end
  end
end
