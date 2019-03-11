set :output, "#{path}/log/cron.log"

every 5.minute do
  rake "chart:aggregate_5_mins_data"
end

every 15.minute do
  rake "chart:aggregate_15_mins_data"
end

every 1.hour do
  rake "chart:aggregate_hourly_data"
end

every 1.day do
  rake "chart:aggregate_daily_data"
end