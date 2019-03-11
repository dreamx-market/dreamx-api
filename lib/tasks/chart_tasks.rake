namespace :chart do
  task :aggregate_5_mins_data => :environment do
    ChartDatum.aggregate(5.minutes)
  end

  task :aggregate_15_mins_data => :environment do
    ChartDatum.aggregate(15.minutes)
  end

  task :aggregate_hourly_data => :environment do
    ChartDatum.aggregate(1.hour)
  end

  task :aggregate_daily_data => :environment do
    ChartDatum.aggregate(1.day)
  end
end