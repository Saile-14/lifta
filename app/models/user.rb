class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :bodyweight_entries, dependent: :destroy
  has_many :lifts, dependent: :destroy

  enum :sex, { male: 0, female: 1 }
  enum :weight_unit, { kg: 0, lb: 1 }, default: :kg

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :sex, presence: true

  def current_bodyweight_kg
    bodyweight_entries.order(recorded_at: :desc).first&.kilograms
  end

  def best_lift(exercise)
    lifts.where(exercise: exercise).max_by(&:dots_score)
  end

  def rank_for(exercise)
    best_lift(exercise)&.benchmark
  end
end
