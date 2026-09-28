# Public profile pages, for lifters who opted in.
class LiftersController < ApplicationController
  allow_unauthenticated_access only: :show
  before_action :resume_session, only: :show

  def show
    @username = WidthNormalization.normalize(params[:username].to_s).downcase
    @lifter = User.find_by(username: @username)
    return not_found unless @lifter && visible?(@lifter)

    @rank_cards = Discipline.all.map { |discipline| RankCard.new(@lifter, discipline) }
    @combo_card = ComboCard.new(@lifter)
  end

  private
    # Private profiles are only visible to their owner (and admins).
    def visible?(lifter)
      lifter.public_profile? || lifter == Current.user || Current.user&.admin?
    end

    # Rendered here, in the app's own layout (nav, language button and all),
    # rather than raised to the static public/404.html, which would also
    # drop the visitor's language. A private profile reads the same as a
    # missing one, so the page doesn't give away that a username exists.
    def not_found
      render :not_found, status: :not_found
    end
end
