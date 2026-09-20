module WeightConversion
  KG_PER_LB = 0.45359237

  module_function

  # Full-width digits from a Japanese IME ("１００") read as 0.0 through
  # to_f, so fold them to ASCII first (see WidthNormalization).
  def to_kg(amount, unit)
    amount = WidthNormalization.normalize(amount.to_s).to_f
    unit.to_s == "lb" ? amount * KG_PER_LB : amount
  end

  def from_kg(kilograms, unit)
    kilograms = kilograms.to_f
    unit.to_s == "lb" ? kilograms / KG_PER_LB : kilograms
  end
end
