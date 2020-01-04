class Integer
  def to_hex_string
    "0x" + self.to_s(16)
  end

  def from_wei
    formatter = Ethereum::Formatter.new
    formatter.from_wei(self)
  end

  def to_wei
    formatter = Ethereum::Formatter.new
    formatter.to_wei(self)
  end
end