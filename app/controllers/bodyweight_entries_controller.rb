class BodyweightEntriesController < ApplicationController
  def index
    @bodyweight_entries = Current.user.bodyweight_entries.order(recorded_at: :desc)
  end

  def new
    @bodyweight_entry = Current.user.bodyweight_entries.new
  end

  def create
    @bodyweight_entry = Current.user.bodyweight_entries.new(bodyweight_entry_params)

    if @bodyweight_entry.save
      redirect_to bodyweight_entries_path, notice: "Bodyweight logged."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def bodyweight_entry_params
    raw = params.require(:bodyweight_entry).permit(:weight, :unit, :recorded_at)
    unit = raw[:unit].presence || Current.user.weight_unit

    {
      kilograms: WeightConversion.to_kg(raw[:weight], unit),
      recorded_at: raw[:recorded_at].presence
    }
  end
end
