module ApplicationHelper
  # The viewer's preferred unit; visitors see kilograms.
  def weight_unit
    Current.user&.weight_unit || "kg"
  end

  # "142.5 kg" / "315 lb" -- weights are stored in kg and shown in the
  # viewer's unit.
  def format_weight(kilograms, unit: weight_unit)
    return "–" if kilograms.nil?

    "#{weight_value(kilograms, unit: unit)} #{unit}"
  end

  # A stored weight as a plain number in the given unit, for form fields.
  def weight_value(kilograms, unit: weight_unit)
    return if kilograms.nil?

    number_with_precision(WeightConversion.from_kg(kilograms, unit), precision: 2, strip_insignificant_zeros: true)
  end

  def format_date(date)
    date&.strftime("%b %-d, %Y")
  end

  def format_time(time)
    time&.strftime("%b %-d, %Y · %H:%M")
  end

  # Discipline tabs; `path` builds the link for each discipline.
  def discipline_tabs(current, label: "Discipline", &path)
    tag.nav(class: "tabs", aria: { label: label }) do
      safe_join(Discipline.all.map do |discipline|
        link_to discipline.name, path.call(discipline), aria: { current: ("page" if discipline == current) }
      end)
    end
  end
end
