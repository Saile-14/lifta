# Picks the language for each request: a ?locale= link (the language button
# in the header, or a shared link), then the language chosen before, then the
# browser's preferred languages, then English.
module Localization
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  private
    def switch_locale(&action)
      I18n.with_locale(chosen_locale || browser_locale || I18n.default_locale, &action)
    end

    # A ?locale= link sticks, so following ones don't need it.
    def chosen_locale
      if (locale = supported_locale(params[:locale]))
        cookies.permanent[:locale] = { value: locale, same_site: :lax }
        locale
      else
        supported_locale(cookies[:locale])
      end
    end

    # "ja-JP,ja;q=0.9,en-US;q=0.8" -> :ja. Browsers list languages in order of
    # preference, so the first one we have wins.
    def browser_locale
      request.headers["Accept-Language"].to_s.split(",").each do |entry|
        locale = supported_locale(entry.split(";").first.to_s.strip.split("-").first)
        return locale if locale
      end
      nil
    end

    def supported_locale(value)
      I18n.available_locales.find { |locale| locale.to_s == value.to_s.strip.downcase }
    end
end
