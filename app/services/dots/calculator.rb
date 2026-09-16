
module Dots
  class Calculator
    # Coefficients per published DOTS formula
    COEFFICIENTS = {
      male:   { a: -307.75076,  b: 24.0900756, c: -0.1918759221, d: 0.0007391293,  e: -0.000001093 },
      female: { a: -57.96288,   b: 13.6175032, c: -0.1126655,    d: 0.0005158568,  e: -0.0000010706 }
    }.freeze

    def initialize(weight_lifted:, bodyweight:, sex:)
      @weight_lifted = weight_lifted.to_f
      @bodyweight = bodyweight.to_f
      @sex = sex.to_sym
    end

    def call
      coeffs = COEFFICIENTS.fetch(@sex) { raise ArgumentError, "unsupported sex: #{@sex}" }
      denominator = polynomial(coeffs, @bodyweight)
      (@weight_lifted * 500.0 / denominator).round(2)
    end

    private

    def polynomial(c, bw)
      c[:a] + c[:b] * bw + c[:c] * bw**2 + c[:d] * bw**3 + c[:e] * bw**4
    end
  end
end
