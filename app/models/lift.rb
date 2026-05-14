class Lift < ApplicationRecord
  include Notifications
  has_one_attached :image
  validates :name, presence: true
  validates :count, numericality: { greater_than_or_equal_to: 0 }
  has_rich_text :description
end
