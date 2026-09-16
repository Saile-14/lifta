FactoryBot.define do
  factory :bodyweight_entry do
    user
    kilograms { 80.0 }
    recorded_at { Time.current }
  end
end
