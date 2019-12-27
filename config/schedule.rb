job_type :rake, 'export PATH="$HOME/.rbenv/bin:$PATH"; eval "$(rbenv init -)"; cd :path && :environment_variable=:environment bundle exec rake :task --silent :output'
job_type :rake_with_lock, 'export PATH="$HOME/.rbenv/bin:$PATH"; eval "$(rbenv init -)"; cd :path && :environment_variable=:environment flock -n /var/lock/:task.lock bundle exec rake :task --silent :output'
env :PATH, ENV['PATH'] 
set :output, "#{path}/log/cron.log"

every 1.minutes do
  rake_with_lock "block:process_new_confirmed_blocks"
  rake_with_lock "transaction:broadcast_expired_transactions"
  rake_with_lock "transaction:confirm_mined_transactions"
end

every 5.minutes do
  rake_with_lock "chart:aggregate_5m"
end

every 15.minutes do
  rake_with_lock "chart:aggregate_15m"
end

every 1.hour do
  rake_with_lock "chart:aggregate_hourly"
end

every 1.day do
  rake_with_lock "chart:aggregate_daily"
end

every 7.days do
  rake_with_lock "chart:remove_expired"
end

# TEMPORARY
every 1.hour + 5.minutes do
  rake_with_lock "faucet:request_ether"
end
