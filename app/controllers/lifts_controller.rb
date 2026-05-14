class LiftsController < ApplicationController
  before_action :load_lift, only: %i[edit show update destroy]
  allow_unauthenticated_access only: %i[index]

  def index
    @lifts = Lift.all
  end

  def show
  end

  def usershow
    @user = User.find(params[:id])
  end

  def new
    @lift = Lift.new
  end

  def create
    @lift = Lift.new lift_params
    if @lift.save
      redirect_to @lift
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @lift.update(lift_params)
      redirect_to @lift
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @lift.destroy
    redirect_to lifts_path
  end

  private

  def lift_params
    params.expect(lift: [ :name, :description, :image, :count ])
  end

  def load_lift
    @lift = Lift.find(params[:id])
  end
end
