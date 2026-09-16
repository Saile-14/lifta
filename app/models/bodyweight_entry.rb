class BodyweightEntry < ApplicationRecord
  belongs_to :user

  validates :kilograms, presence: true, numericality: { greater_than: 0 }
  validates :recorded_at, presence: true

  before_validation :default_recorded_at, on: :create

  private

  def default_recorded_at
    self.recorded_at ||= Time.current
  end
end
