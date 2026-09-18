module Sinclair
  # The IWF's Sinclair coefficient, which scales a weightlifting result up to
  # what it would be worth at heavyweight bodyweight. Uses the 2021-2024
  # Olympic-cycle constants: the 2025-2028 ones haven't been published yet
  # (the weight classes changed in 2025).
  class Calculator
    COEFFICIENTS = {
      male:   { a: 0.722762521, b: 193.609 },
      female: { a: 0.787004341, b: 153.757 }
    }.freeze

    # Multiplier that turns kilograms lifted into Sinclair points. Lifters at
    # or above the reference bodyweight (b) aren't adjusted.
    def self.coefficient(bodyweight:, sex:)
      c = COEFFICIENTS.fetch(sex.to_sym) { raise ArgumentError, "unsupported sex: #{sex}" }
      bodyweight = bodyweight.to_f
      return 1.0 if bodyweight >= c[:b]

      10**(c[:a] * Math.log10(bodyweight / c[:b])**2)
    end

    def initialize(weight_lifted:, bodyweight:, sex:)
      @weight_lifted = weight_lifted.to_f
      @bodyweight = bodyweight.to_f
      @sex = sex
    end

    def call
      (@weight_lifted * self.class.coefficient(bodyweight: @bodyweight, sex: @sex)).round(2)
    end
  end
end
