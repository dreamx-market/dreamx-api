class NonceValidator < ActiveModel::EachValidator
	def validate_each(record, attribute, value)
		last_record = record.class.last
		if last_record && value.to_i <= last_record.nonce.to_i then
			record.errors[attribute] << (options[:message] || "must be greater than last nonce")
		end
	end
end