module LiftsHelper
  # "140 kg × 3", "185 kg", "12 reps", "8 reps +20 kg"
  def lift_result(lift, unit: weight_unit)
    if lift.discipline.weighted?
      weight = format_weight(lift.weight_lifted, unit: unit)
      lift.reps > 1 ? t("lift_results.set", weight: weight, reps: lift.reps) : weight
    else
      reps = t("lift_results.reps", count: lift.reps)
      return reps unless lift.weight_lifted.to_f.positive?

      t("lift_results.added_weight", reps: reps, weight: format_weight(lift.weight_lifted, unit: unit))
    end
  end

  # "137.91 DOTS", "150.51 Sinclair", "17.5 reps"
  def format_score(score, discipline)
    t("scores.#{discipline.key}", score: score_number(score), count: score.to_f)
  end

  def score_number(score)
    number_with_precision(score, precision: 2, strip_insignificant_zeros: true)
  end

  def tier_badge(tier)
    return tag.span(t("tiers.unranked"), class: "tier-badge") unless tier

    tag.span(t("tiers.badge", tier: tier.label, percent: tier.display_percent), class: "tier-badge tier-badge--#{tier.name}")
  end

  def status_badge(lift)
    case lift.status
    when "pending" then tag.span(t("statuses.pending"), class: "badge badge--pending")
    when "rejected" then tag.span(t("statuses.rejected"), class: "badge badge--rejected")
    end
  end

  # "Gold at 187.5 kg, or 162.5 kg × 5" / "Gold at 15 reps"
  def target_text(target, unit: weight_unit)
    tier = t("tiers.#{target.tier_name}")

    if target.reps
      t("targets.reps", tier: tier, reps: t("lift_results.reps", count: target.reps))
    elsif target.set_weight_kg
      t("targets.weight_or_set", tier: tier, weight: format_weight(target.weight_kg, unit: unit),
        set_weight: format_weight(target.set_weight_kg, unit: unit), set_reps: target.set_reps)
    else
      t("targets.weight", tier: tier, weight: format_weight(target.weight_kg, unit: unit))
    end
  end

  # The line under a rank meter on the dashboard.
  def rank_row_detail(row)
    return t("ranks.unranked_row", exercise: row.exercise.name.downcase) unless row.lift

    best = t("ranks.best", result: lift_result(row.lift), date: format_date(row.lift.lifted_at))
    next_up = row.target ? t("ranks.next", target: target_text(row.target)) : t("ranks.top_tier")
    "#{best} · #{next_up}"
  end

  def overall_detail(card)
    if card.complete?
      if card.total_score
        t("totals.#{card.discipline.key}", points: score_number(card.total_score))
      else
        t("ranks.overall_average", count: card.rows.size)
      end
    else
      missing = card.rows.reject(&:lift).map { |row| row.exercise.name.downcase }
      t("ranks.overall_missing", lifts: missing.to_sentence)
    end
  end
end
