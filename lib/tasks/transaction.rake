namespace :transaction do
  task :broadcast_expired_transactions => :environment do
    Transaction.broadcast_expired_transactions
  end

  task :confirm_transactions => :environment do
    Transaction.confirm_transactions
  end
end