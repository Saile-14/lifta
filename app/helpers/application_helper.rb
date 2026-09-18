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

  # "Sep 18, 2026" / "2026年9月18日"
  def format_date(date)
    l(date.to_date, format: :medium) if date
  end

  def format_time(time)
    l(time, format: :medium) if time
  end

  def page_title(title)
    content_for :title, t("page_title", title: title)
  end

  # Discipline tabs; `path` builds the link for each discipline.
  def discipline_tabs(current, &path)
    tag.nav(class: "tabs", aria: { label: t("discipline_tabs.label") }) do
      safe_join(Discipline.all.map do |discipline|
        link_to discipline.name, path.call(discipline), aria: { current: ("page" if discipline == current) }
      end)
    end
  end

  # This page in another language. A ?locale= link also remembers the choice
  # (see Localization).
  def localized_url(locale)
    "#{request.base_url}#{request.path}?#{request.query_parameters.merge("locale" => locale.to_s).to_query}"
  end

  # The language button: the other language, named in that language.
  def locale_switch_link
    other = (I18n.available_locales - [ I18n.locale ]).first
    # A full page load (no Turbo) so <html lang> and fonts switch too; also
    # keeps Turbo from prefetching it on hover.
    link_to t("locale_name", locale: other), localized_url(other),
      class: "locale-switch", lang: other, hreflang: other, data: { turbo: false }
  end
end
