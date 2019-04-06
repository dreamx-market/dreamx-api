namespace :cron do
 task :every_5m => :environment do
  ChartDatum.aggregate(5.minutes)
  Block.process_new_confirmed_blocks
  Transaction.rebroadcast_expired_transactions
  Transaction.confirm_mined_transactions
 end

 task :every_1m => :environment do
  p 'LOL'
 end
end