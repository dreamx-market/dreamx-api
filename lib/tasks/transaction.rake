namespace :transaction do
  task :broadcast_expired_transactions => :environment do
    Block.broadcast_expired_transactions
  end

  task :confirm_mined_transactions => :environment do
    Block.confirm_mined_transactions
  end
end