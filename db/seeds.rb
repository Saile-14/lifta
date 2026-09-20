# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Ranking is formula-based (DOTS, Sinclair, and rep ladders -- see app/models/discipline), not looked up from a
# seeded reference table, so there's no strength-standards data to load here. This just creates demo accounts for
# local development: an admin, a demo lifter, and a few listed lifters so the leaderboard has people on it.

if Rails.env.development?
  def seed_user(email, username:, sex: :male, admin: false, listed: true, badges: [ ComboCard::KEY ])
    User.find_or_initialize_by(email_address: email).tap do |user|
      user.password = "password123" if user.new_record?
      user.update!(username: username, sex: sex, admin: admin, public_profile: listed, featured_badges: badges)
    end
  end

  # lifts: [exercise, kg (added kg for calisthenics), reps]; one per exercise, logged over the past few weeks.
  def seed_lifts(user, bodyweight:, lifts:)
    user.bodyweight_entries.create!(kilograms: bodyweight, recorded_at: 60.days.ago) unless user.bodyweight_entries.exists?

    lifts.each_with_index do |(exercise, kg, reps), index|
      next if user.lifts.exists?(exercise: exercise)

      user.lifts.create!(exercise: exercise, weight_lifted: kg, reps: reps, lifted_at: (30 - index * 3).days.ago.to_date)
    end
  end

  seed_user("admin@example.com", username: "coach", admin: true, listed: false)

  demo = seed_user("demo@example.com", username: "demo", badges: [ ComboCard::KEY, "calisthenics" ])
  seed_lifts demo, bodyweight: 80, lifts: [
    [ :squat, 120, 3 ], [ :bench, 90, 1 ], [ :deadlift, 160, 1 ],
    [ :snatch, 70, 1 ], [ :clean_and_jerk, 90, 1 ],
    [ :pull_up, 0, 12 ], [ :dip, 0, 18 ], [ :push_up, 0, 40 ]
  ]

  seed_lifts seed_user("sofia@example.com", username: "sofia_lifts", sex: :female), bodyweight: 63, lifts: [
    [ :squat, 130, 1 ], [ :bench, 75, 1 ], [ :deadlift, 160, 2 ], [ :snatch, 65, 1 ], [ :clean_and_jerk, 85, 1 ]
  ]

  seed_lifts seed_user("tom@example.com", username: "big_tom", badges: [ "powerlifting" ]), bodyweight: 105, lifts: [
    [ :squat, 250, 1 ], [ :bench, 170, 1 ], [ :deadlift, 290, 1 ]
  ]

  seed_lifts seed_user("mia@example.com", username: "mia_moves", sex: :female), bodyweight: 58, lifts: [
    [ :pull_up, 0, 12 ], [ :dip, 0, 20 ], [ :push_up, 0, 35 ], [ :squat, 90, 5 ], [ :bench, 50, 3 ], [ :deadlift, 120, 3 ]
  ]

  seed_lifts seed_user("kenji@example.com", username: "kenji"), bodyweight: 73, lifts: [
    [ :snatch, 120, 1 ], [ :clean_and_jerk, 150, 1 ], [ :squat, 190, 1 ], [ :bench, 120, 1 ], [ :deadlift, 220, 1 ]
  ]

  seed_lifts seed_user("ray@example.com", username: "rookie_ray"), bodyweight: 90, lifts: [
    [ :squat, 80, 5 ], [ :bench, 60, 5 ], [ :deadlift, 110, 5 ], [ :pull_up, 0, 4 ], [ :dip, 0, 6 ], [ :push_up, 0, 20 ]
  ]

  seed_lifts seed_user("sam@example.com", username: "streetlift_sam"), bodyweight: 75, lifts: [
    [ :pull_up, 40, 5 ], [ :dip, 60, 5 ], [ :push_up, 0, 70 ]
  ]

  # A claim for the admin review queue: a diamond-level deadlift.
  bold = seed_user("bold@example.com", username: "bold_claims")
  seed_lifts bold, bodyweight: 83, lifts: [ [ :squat, 200, 1 ], [ :bench, 140, 1 ], [ :deadlift, 330, 1 ] ]

  puts "Seeded demo@example.com and admin@example.com (password123), plus #{User.listed.count - 1} listed lifters."
  puts "#{Lift.pending.count} lift(s) waiting in the admin review queue."
end
