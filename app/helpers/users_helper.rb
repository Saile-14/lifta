module UsersHelper
  # Time zone options valued by IANA name (what browsers report), keeping the
  # user's current zone even when it isn't one of Rails' named zones.
  def time_zone_options(current)
    options = ActiveSupport::TimeZone.all.map { |zone| [ zone.to_s, zone.tzinfo.name ] }.uniq(&:last)
    options.unshift([ current, current ]) if current.present? && options.none? { |_, value| value == current }
    options_for_select(options, current)
  end

  def sex_options
    User.sexes.keys.map { |sex| [ t("sexes.#{sex}"), sex ] }
  end

  # The ranks a lifter chose to show off, in BADGES order. Ones they haven't
  # earned are skipped rather than shown empty: a discipline has no tier
  # until every exercise in it has an approved lift, and a combined rank
  # means nothing with nothing logged.
  def featured_badges(user, combo_card)
    items = user.featured_badges.filter_map do |badge|
      name, tier = featured_rank(combo_card, badge)
      next unless tier

      tag.span(safe_join([ tag.span(name, class: "badge-set__label"), tier_badge(tier) ], " "),
        class: "badge-set__item")
    end

    tag.span(safe_join(items), class: "badge-set") if items.any?
  end

  # [name, tier] for one badge key; the tier is nil when it isn't earned yet.
  def featured_rank(combo_card, badge)
    if badge == ComboCard::KEY
      [ t("ranks.combo"), (combo_card.tier if combo_card.ranked?) ]
    else
      discipline = Discipline.find(badge)
      [ discipline.name, combo_card.row_for(discipline).tier ]
    end
  end

  # One-line summary of a lifter's overall ranks, for link previews.
  def ranks_summary(rank_cards)
    rank_cards.map do |card|
      t("ranks.summary", discipline: card.discipline.name, rank: card.overall&.to_s || t("ranks.unranked_summary"))
    end.join(" · ")
  end
end
