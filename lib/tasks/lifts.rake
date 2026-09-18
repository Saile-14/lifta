namespace :lifts do
  desc "Recompute every lift's stored score, e.g. after changing a scoring formula"
  task rescore: :environment do
    count = 0
    Lift.includes(:user).find_each do |lift|
      lift.rescore!
      count += 1
    end
    puts "Rescored #{count} lifts."
  end
end
