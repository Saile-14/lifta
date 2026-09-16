# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Ranking is formula-based (the DOTS score, see app/services/dots), not looked up from a
# seeded reference table, so there's no strength-standards data to load here. This just
# creates a demo account for local development.

if Rails.env.development?
  demo = User.find_or_create_by!(email_address: "demo@example.com") do |user|
    user.password = "password123"
    user.sex = :male
    user.weight_unit = :kg
  end

  demo.bodyweight_entries.find_or_create_by!(recorded_at: 30.days.ago) { |e| e.kilograms = 82 }
  demo.bodyweight_entries.find_or_create_by!(recorded_at: Time.current) { |e| e.kilograms = 80 }

  demo.lifts.find_or_create_by!(exercise: :squat, lifted_at: 20.days.ago) do |lift|
    lift.weight_lifted = 120
    lift.reps = 3
  end
  demo.lifts.find_or_create_by!(exercise: :bench, lifted_at: 10.days.ago) do |lift|
    lift.weight_lifted = 90
    lift.reps = 1
  end
  demo.lifts.find_or_create_by!(exercise: :deadlift, lifted_at: Date.current) do |lift|
    lift.weight_lifted = 160
    lift.reps = 1
  end

  puts "Seeded demo@example.com / password123"
end
