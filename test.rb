def calculate_take_amount(give_amount, total_give, total_take)
  take_amount = give_amount * total_take / total_give
  return take_amount
end

order = { :give_amount => 195738239776775570, :take_amount => 59744193591648150 }
fill_amount = 50000000000000000
# calculatedTakeAmount = fillAmount * order[:giveAmount] / order[:takeAmount]
# calculatedGiveAmount = calculatedTakeAmount * order[:takeAmount] / order[:giveAmount]

calculatedTakeAmount = calculate_take_amount(fill_amount, order[:give_amount], order[:take_amount])

pp calculatedTakeAmount
