job_type :rake, 'export PATH="$HOME/.rbenv/bin:$PATH"; eval "$(rbenv init -)"; cd :path && :environment_variable=:environment bundle exec rake :task --silent :output'
job_type :rake_with_lock, 'export PATH="$HOME/.rbenv/bin:$PATH"; eval "$(rbenv init -)"; cd :path && :environment_variable=:environment flock -n /var/lock/:task.lock bundle exec rake :task --silent :output'
env :PATH, ENV['PATH'] 
set :output, "#{path}/log/cron.log"

every 1.minute do
  rake_with_lock "cron:a_lengthy_task"
end

# every 5.minutes do
#   rake "cron:every_5m"
# end

# every 15.minutes do
#   rake "chart:aggregate_15m"
# end

# every 1.hour do
#   rake "chart:aggregate_hourly"
# end

# every 1.day do
#   rake "chart:aggregate_daily"
# end

# every 7.days do
#   rake "chart:remove_expired"
# end