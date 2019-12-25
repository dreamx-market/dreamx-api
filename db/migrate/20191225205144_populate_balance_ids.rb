class PopulateBalanceIds < ActiveRecord::Migration[5.2]
  def change
    Deposit.all.each do |d|
      d.set_balance
      d.save
    end
    Order.all.each do |o|
      o.set_balance
      o.save
    end
    OrderCancel.all.each do |o|
      o.set_balance
      o.save
    end
    Trade.all.each do |t|
      t.set_balance
      t.save
    end
    Withdraw.all.each do |w|
      w.set_balance
      w.save
    end
  end
end
