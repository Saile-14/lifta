namespace :admin do
  desc 'Make a user an admin: bin/rails "admin:grant[you@example.com]"'
  task :grant, [ :email ] => :environment do |_task, args|
    user = User.find_by(email_address: args[:email].to_s.strip.downcase) or abort "No user with email #{args[:email].inspect}."
    user.update!(admin: true)
    puts "#{user.email_address} (@#{user.username}) is now an admin."
  end

  desc 'Take admin rights away: bin/rails "admin:revoke[you@example.com]"'
  task :revoke, [ :email ] => :environment do |_task, args|
    user = User.find_by(email_address: args[:email].to_s.strip.downcase) or abort "No user with email #{args[:email].inspect}."
    user.update!(admin: false)
    puts "#{user.email_address} (@#{user.username}) is no longer an admin."
  end
end
