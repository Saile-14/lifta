# Public profile pages, for lifters who opted in.
class LiftersController < ApplicationController
  allow_unauthenticated_access only: :show
  before_action :resume_session, only: :show

  def show
    @lifter = User.find_by!(username: WidthNormalization.normalize(params[:username].to_s).downcase)
    raise ActiveRecord::RecordNotFound unless visible?(@lifter)

    @rank_cards = Discipline.all.map { |discipline| RankCard.new(@lifter, discipline) }
    @combo_card = ComboCard.new(@lifter)
  end

  private
    # Private profiles are only visible to their owner (and admins).
    def visible?(lifter)
      lifter.public_profile? || lifter == Current.user || Current.user&.admin?
    end
end
