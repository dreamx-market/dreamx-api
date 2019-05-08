namespace :transaction do
  task :broadcast_expired_transactions => :environment do
    Transaction.broadcast_expired_transactions
  end

  task :confirm_mined_transactions => :environment do
    Transaction.confirm_mined_transactions
  end
end