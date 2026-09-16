
module Dots
  Tier = Struct.new(:name, :fill_percent) do
    WORLD_RECORD_DOTS = 600.0

    THRESHOLDS = [
      [ 40,   :bronze ],
      [ 60,   :silver ],
      [ 75,   :gold ],
      [ 90,   :platinum ],
      [ 99.9, :diamond ]
    ].freeze

    def self.for(score:)
      pct = [ (score / WORLD_RECORD_DOTS) * 100.0, 100.0 ].min.round(1)
      name = THRESHOLDS.find { |max_pct, _| pct <= max_pct }&.last || :elite
      new(name, pct)
    end
  end
end
