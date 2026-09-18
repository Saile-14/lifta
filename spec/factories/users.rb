FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "lifter_#{n}" }
    password { "password123" }
    sex { :male }

    trait :admin do
      admin { true }
    end

    trait :listed do
      public_profile { true }
    end
  end
end
