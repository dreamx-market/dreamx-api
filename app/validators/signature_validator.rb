class SignatureValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    begin
      recovered_public_key = Eth::Key.personal_recover_hex(value, record.signature)
      recovered_address = Eth::Utils.public_key_to_address recovered_public_key
    rescue
    end
    if (!recovered_address or recovered_address != Eth::Utils.format_address(record.account_address)) then
      record.errors[:signature] << (options[:message] || "invalid")
    end
  end
end