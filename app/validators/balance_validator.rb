# class BalanceValidator < ActiveModel::EachValidator
# 	def validate_each(record, attribute, value)
# 		balance = Balance.find_by(account_address: record.account_address, token_address: record.give_token_address)
# 		if !balance || balance.balance.to_i < record.give_amount.to_i then
# 			record.errors[attribute] << (options[:message] || 'insufficient balance')
# 		end
# 	end
# end