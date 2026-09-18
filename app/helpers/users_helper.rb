module UsersHelper
  # Time zone options valued by IANA name (what browsers report), keeping the
  # user's current zone even when it isn't one of Rails' named zones.
  def time_zone_options(current)
    options = ActiveSupport::TimeZone.all.map { |zone| [ zone.to_s, zone.tzinfo.name ] }.uniq(&:last)
    options.unshift([ current, current ]) if current.present? && options.none? { |_, value| value == current }
    options_for_select(options, current)
  end

  # One-line summary of a lifter's overall ranks, for link previews.
  def ranks_summary(rank_cards)
    rank_cards.map do |card|
      overall = card.overall
      "#{card.discipline.name}: #{overall ? overall.to_s : "unranked"}"
    end.join(" · ")
  end
end
