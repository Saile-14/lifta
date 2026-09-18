module LiftsHelper
  # "140 kg × 3", "185 kg", "12 reps", "8 reps +20 kg"
  def lift_result(lift, unit: weight_unit)
    if lift.discipline.weighted?
      [ format_weight(lift.weight_lifted, unit: unit), ("× #{lift.reps}" if lift.reps > 1) ].compact.join(" ")
    else
      [ pluralize(lift.reps, "rep"), ("+#{format_weight(lift.weight_lifted, unit: unit)}" if lift.weight_lifted.to_f.positive?) ].compact.join(" ")
    end
  end

  def format_score(score, discipline)
    "#{number_with_precision(score, precision: 2, strip_insignificant_zeros: true)} #{discipline.score_label}"
  end

  def tier_badge(tier)
    return tag.span("Unranked", class: "tier-badge") unless tier

    tag.span("#{tier.label} · #{tier.display_percent}%", class: "tier-badge tier-badge--#{tier.name}")
  end

  def status_badge(lift)
    case lift.status
    when "pending" then tag.span("Pending review", class: "badge badge--pending")
    when "rejected" then tag.span("Rejected", class: "badge badge--rejected")
    end
  end

  # "Gold at 187.5 kg, or 162.5 kg × 5" / "Gold at 15 reps"
  def target_text(target, unit: weight_unit)
    tier = target.tier_name.to_s.capitalize

    if target.reps
      "#{tier} at #{pluralize(target.reps, "rep")}"
    elsif target.set_weight_kg
      "#{tier} at #{format_weight(target.weight_kg, unit: unit)}, or #{format_weight(target.set_weight_kg, unit: unit)} × #{target.set_reps}"
    else
      "#{tier} at #{format_weight(target.weight_kg, unit: unit)}"
    end
  end

  # The line under a rank meter on the dashboard.
  def rank_row_detail(row)
    return "Log a #{row.exercise.name.downcase} to get ranked." unless row.lift

    best = "Best: #{lift_result(row.lift)}"
    best += " (#{format_date(row.lift.lifted_at)})"
    next_up = row.target ? "Next: #{target_text(row.target)}" : "Top tier."
    "#{best} · #{next_up}"
  end

  def overall_detail(card)
    if card.complete?
      card.total_score ? "#{format_score(card.total_score, card.discipline)} total" : "Average of your #{card.rows.size} lifts."
    else
      missing = card.rows.reject(&:lift).map { |row| row.exercise.name.downcase }
      "Log #{missing.to_sentence} for an overall rank."
    end
  end
end
