FactoryBot.define do
  factory :lift do
    user
    exercise { :squat }
    weight_lifted { 100 }
    reps { 1 }
    lifted_at { Date.current }
  end
end
