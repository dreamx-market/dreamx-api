def calculate_take_amount(give_amount, total_give, total_take)
  take_amount = total_take * give_amount / total_give
  return take_amount
end

def calculate_give_amount(take_amount, total_give, total_take)
  give_amount = total_give * take_amount / total_take
  return give_amount
end

def calculate_fee(amount, fee)
  one_ether = 1000000000000000000
  fee_amount = amount * fee / one_ether
end

total_give = 195738239776775570
total_take = 59744193591648150
take_amount = 50000000000000000

calculated_give_amount = calculate_give_amount(take_amount, total_give, total_take)
calculated_take_amount = calculate_take_amount(calculated_give_amount, total_give, total_take)

# pp calculated_give_amount
# pp calculated_take_amount

maker_fee = 1000000000000000
taker_fee = 2000000000000000
maker_fee_amount = calculate_fee(calculated_take_amount, maker_fee)
taker_fee_amount = calculate_fee(calculated_give_amount, taker_fee)

pp maker_fee_amount
pp taker_fee_amount
