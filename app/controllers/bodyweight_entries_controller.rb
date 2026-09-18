class BodyweightEntriesController < ApplicationController
  before_action :set_bodyweight_entry, only: %i[ edit update destroy ]

  def index
    @bodyweight_entries = Current.user.bodyweight_entries.order(recorded_at: :desc)
  end

  def new
    @bodyweight_entry = Current.user.bodyweight_entries.new
  end

  def create
    @bodyweight_entry = Current.user.bodyweight_entries.new(bodyweight_entry_params)

    if @bodyweight_entry.save
      redirect_to bodyweight_entries_path, notice: t(".logged")
    else
      @values = form_params.to_h
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @bodyweight_entry.update(bodyweight_entry_params)
      redirect_to bodyweight_entries_path, notice: t(".updated")
    else
      @values = form_params.to_h
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @bodyweight_entry.destroy
    redirect_to bodyweight_entries_path, notice: t(".deleted"), status: :see_other
  end

  private
    def set_bodyweight_entry
      @bodyweight_entry = Current.user.bodyweight_entries.find(params[:id])
    end

    def form_params
      params.require(:bodyweight_entry).permit(:weight, :unit, :recorded_at)
    end

    def bodyweight_entry_params
      raw = form_params
      unit = raw[:unit].presence_in(%w[ kg lb ]) || Current.user.weight_unit

      {
        kilograms: (WeightConversion.to_kg(raw[:weight], unit) if raw[:weight].present?),
        recorded_at: raw[:recorded_at].presence
      }
    end
end
