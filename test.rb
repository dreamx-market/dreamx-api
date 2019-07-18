def calculate_take_amount(give_amount, total_give, total_take)
  take_amount = give_amount * total_give / total_take
  return take_amount
end

order = { :giveAmount => 195738239776775570, :takeAmount => 59744193591648150 }
fillAmount = 50000000000000000
# calculatedTakeAmount = fillAmount * order[:giveAmount] / order[:takeAmount]
# calculatedGiveAmount = calculatedTakeAmount * order[:takeAmount] / order[:giveAmount]

calculatedTakeAmount = calculate_take_amount(6, 10, 5)

pp calculatedTakeAmount
