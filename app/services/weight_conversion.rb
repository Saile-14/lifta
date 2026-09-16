module WeightConversion
  KG_PER_LB = 0.45359237

  module_function

  def to_kg(amount, unit)
    amount = amount.to_f
    unit.to_s == "lb" ? amount * KG_PER_LB : amount
  end

  def from_kg(kilograms, unit)
    kilograms = kilograms.to_f
    unit.to_s == "lb" ? kilograms / KG_PER_LB : kilograms
  end
end
