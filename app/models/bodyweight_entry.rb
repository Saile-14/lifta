class BodyweightEntry < ApplicationRecord
  belongs_to :user

  validates :kilograms, presence: true
  validates :kilograms, numericality: { greater_than: 20, less_than: 400, message: :implausible_weight }, allow_nil: true
  validates :recorded_at, presence: true

  before_validation :default_recorded_at, on: :create

  private

  def default_recorded_at
    self.recorded_at ||= Time.current
  end
end
