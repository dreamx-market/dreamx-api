job_type :rake, 'export PATH="$HOME/.rbenv/bin:$PATH"; eval "$(rbenv init -)"; cd :path && :environment_variable=:environment bundle exec rake :task --silent :output'
job_type :rake_with_lock, 'export PATH="$HOME/.rbenv/bin:$PATH"; eval "$(rbenv init -)"; cd :path && :environment_variable=:environment flock -n /var/lock/:task.lock bundle exec rake :task --silent :output'
env :PATH, ENV['PATH'] 
set :output, "#{path}/log/cron.log"

every 1.minutes do
  runner 'Block.process_new_confirmed_blocks'
end

every 5.minutes do
  runner 'ChartDatum.aggregate(5.minutes)'
end

every 15.minutes do
  runner 'ChartDatum.aggregate(15.minutes)'
end

every 1.hour do
  runner 'ChartDatum.aggregate(1.hour)'
end

every 1.day do
  runner 'ChartDatum.aggregate(1.day)'
end

every 7.days do
  runner 'ChartDatum.remove_expired'
end

# TEMPORARY
every 2.hour do
  rake 'faucet:request_ether'
end
