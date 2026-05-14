class SubscribersController < ApplicationController
  allow_unauthenticated_access
  before_action :set_lift


  def create
    @lift.subscribers.where(subscriber_params).first_or_create
    redirect_to @lift, notice: "You are now subscribed"
  end


  private
  def set_lift
    @lift = Lift.find(params[:lift_id])
  end

  def subscriber_params
    params.expect(subscriber: [ :email ])
  end
end
