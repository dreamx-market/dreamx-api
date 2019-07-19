def calculate_take_amount(give_amount, total_give, total_take)
  take_amount = total_take * give_amount / total_give
  return take_amount
end

def calculate_give_amount(take_amount, total_give, total_take)
  give_amount = total_give * take_amount / total_take
  return give_amount
end

total_give = 195738239776775570
total_take = 59744193591648150
take_amount = 50000000000000000

calculated_give_amount = calculate_give_amount(take_amount, total_give, total_take)
calculated_take_amount = calculate_take_amount(calculated_give_amount, total_give, total_take)

pp calculated_give_amount
pp calculated_take_amount
