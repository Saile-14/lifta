# A percentage placed on a named ladder of rungs: which rung it lands on,
# how to label it, and how wide to draw its meter.
#
# Including classes supply a LADDER of rung => minimum percentage (lowest
# first) and an I18N_SCOPE holding the rung labels. Tier ranks one lift or
# one discipline on the bronze -> grandmaster ladder; ComboTier ranks a
# lifter across all three disciplines at once on its own.
module RankLadder
  extend ActiveSupport::Concern

  included do
    include Comparable
  end

  class_methods do
    def names
      self::LADDER.keys
    end

    # Lowest percentage that reaches this rung.
    def minimum_for(name)
      self::LADDER.fetch(name.to_sym)
    end
  end

  attr_reader :percent

  def initialize(percent)
    @percent = percent.to_f
  end

  def name
    self.class.names.reverse.find { |rung| percent >= self.class.minimum_for(rung) } || self.class.names.first
  end

  def label
    I18n.t("#{self.class::I18N_SCOPE}.#{name}")
  end

  def level
    self.class.names.index(name)
  end

  def next_name
    self.class.names[level + 1]
  end

  # Width of the rank meter.
  def fill_percent
    percent.clamp(0.0, 100.0)
  end

  # Floored, so 39.96% reads 39.9% (bronze) rather than rounding up to a
  # silver-looking 40.0%.
  def display_percent
    (percent * 10).floor / 10.0
  end

  def <=>(other)
    percent <=> other.percent
  end

  def to_s
    I18n.t("#{self.class::I18N_SCOPE}.with_percent", tier: label, percent: display_percent)
  end
end
