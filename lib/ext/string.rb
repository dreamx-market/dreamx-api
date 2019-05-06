class String
  def without_prefix
    self[2..-1]
  end

  def without_checksum
    Eth::Utils.prefix_hex(Eth::Utils.bin_to_hex(Eth::Utils.normalize_address(self)))
  end

  def to_ether
    formatter = Ethereum::Formatter.new
    formatter.from_wei(self.to_f).to_s
  end

  def to_wei
    formatter = Ethereum::Formatter.new
    formatter.to_wei(self.to_f).to_s
  end
end