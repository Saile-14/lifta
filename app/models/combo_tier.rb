# A lifter's standing across all three disciplines at once, on its own
# ladder from dormant up to ultimate lifeform.
#
# Separate from Tier, which ranks a single lift or a single discipline. The
# combined percentage averages all three disciplines and counts one you have
# never trained as zero (see ComboCard), so the rungs sit lower than Tier's:
# reaching the top still takes diamond-level strength in powerlifting,
# weightlifting and calisthenics simultaneously, which almost nobody has.
class ComboTier
  include RankLadder

  # Minimum combined percentage for each rung, lowest first.
  LADDER = { dormant: 0, awakened: 15, evolved: 30, apex: 50, transcendent: 70, ultimate_lifeform: 90 }.freeze
  NAMES = LADDER.keys.freeze

  I18N_SCOPE = "combo_tiers"
end
