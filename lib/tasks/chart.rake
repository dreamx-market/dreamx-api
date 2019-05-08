namespace :chart do
  task :aggregate_5m => :environment do
    ChartDatum.aggregate(5.minutes)
  end

  task :aggregate_15m => :environment do
    ChartDatum.aggregate(15.minutes)
  end

  task :aggregate_hourly => :environment do
    ChartDatum.aggregate(1.hour)
  end

  task :aggregate_daily => :environment do
    ChartDatum.aggregate(1.day)
  end

  task :remove_expired => :environment do
    ChartDatum.remove_expired
  end
end