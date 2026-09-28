# sitemap.xml for search engines: the home page, every leaderboard tab and
# every listed lifter's profile, each in both languages, with hreflang
# alternates pointing each language at the other (like the <link
# rel="alternate"> tags in the layout). Private profiles stay out.
class SitemapsController < ApplicationController
  allow_unauthenticated_access

  def show
    @pages = [ ->(locale) { root_url(locale: locale) } ] +
      leaderboard_tabs.map { |tab| ->(locale) { leaderboard_url(**tab, locale: locale) } } +
      User.listed.order(:username).pluck(:username).map { |username| ->(locale) { lifter_url(username, locale: locale) } }

    expires_in 1.hour, public: true
  end

  private
    # The combined board, then each discipline's overall and per-lift boards.
    def leaderboard_tabs
      [ { discipline: ComboCard::KEY } ] + Discipline.all.flat_map do |discipline|
        [ { discipline: discipline.key } ] +
          discipline.exercise_keys.map { |exercise| { discipline: discipline.key, board: exercise } }
      end
    end
end
