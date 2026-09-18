module Dots
  class Calculator
    # Coefficients and bodyweight bounds per the published DOTS formula (as
    # implemented by OpenPowerlifting). Outside the bounds the polynomial stops
    # making sense, so bodyweight is clamped to them.
    COEFFICIENTS = {
      male:   { a: -307.75076,  b: 24.0900756, c: -0.1918759221, d: 0.0007391293,  e: -0.000001093 },
      female: { a: -57.96288,   b: 13.6175032, c: -0.1126655495, d: 0.0005158568,  e: -0.0000010706 }
    }.freeze

    BODYWEIGHT_BOUNDS = { male: 40.0..210.0, female: 40.0..150.0 }.freeze

    # Multiplier that turns kilograms lifted into DOTS points.
    def self.coefficient(bodyweight:, sex:)
      sex = sex.to_sym
      c = COEFFICIENTS.fetch(sex) { raise ArgumentError, "unsupported sex: #{sex}" }
      bw = bodyweight.to_f.clamp(BODYWEIGHT_BOUNDS.fetch(sex))

      500.0 / (c[:a] + c[:b] * bw + c[:c] * bw**2 + c[:d] * bw**3 + c[:e] * bw**4)
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
