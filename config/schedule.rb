env :PATH, ENV['PATH'] 
set :output, "#{path}/log/cron.log"

every 5.minutes do
  rake "cron:every_5m"
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