class SignatureValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    begin
      bin_signature = Eth::Utils.hex_to_bin(record.signature).bytes.rotate(-1).pack('c*')
      recovered_public_key = Eth::OpenSsl.recover_compact(Eth::Utils.keccak256(Eth::Utils.prefix_message(Eth::Utils.hex_to_bin(value))), bin_signature)
      recovered_address = Eth::Utils.public_key_to_address recovered_public_key
    rescue
    end
    if (
      !recovered_address or 
      !Eth::Utils.valid_address?(record.account_address) or
      recovered_address != Eth::Utils.format_address(record.account_address)
    ) then
      record.errors[:signature] << (options[:message] || "invalid")
    end
  end
end