job_type :rake, 'export PATH="$HOME/.rbenv/bin:$PATH"; eval "$(rbenv init -)"; cd :path && :environment_variable=:environment bundle exec rake :task --silent :output'
job_type :rake_with_lock, 'export PATH="$HOME/.rbenv/bin:$PATH"; eval "$(rbenv init -)"; cd :path && :environment_variable=:environment flock -n /var/lock/:task.lock bundle exec rake :task --silent :output'
env :PATH, ENV['PATH'] 
set :output, "#{path}/log/cron.log"

every 1.minutes do
  rake "block:process_new_confirmed_blocks"
end

every 5.minutes do
  rake "chart:aggregate_5m"
end

every 15.minutes do
  rake "chart:aggregate_15m"
end

every 1.hour do
  rake "chart:aggregate_hourly"
end

every 1.day do
  rake "chart:aggregate_daily"
end

every 7.days do
  rake "chart:remove_expired"
end

# TEMPORARY
every 2.hour do
  rake "faucet:request_ether"
end
