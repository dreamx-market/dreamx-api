class String
  def without_prefix
    self[2..-1]
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