RSpec.configure do |config|
  RSpec::Matchers.define :have_decreased do
    supports_block_expectations

    match do |block|
      @first = block_arg.call.to_i
      block.call
      @second = block_arg.call.to_i
      @delta = (@first - @amount) - @second
      return @delta == 0
    end

    chain :by do |amount|
      @amount = amount.to_i
    end

    failure_message do
      "value hasn't been decreased by #{@amount}, before: #{@first}, after: #{@second}, delta: #{@delta}"
    end
  end

  RSpec::Matchers.define :have_increased do
    supports_block_expectations

    match do |block|
      @first = block_arg.call.to_i
      block.call
      @second = block_arg.call.to_i
      @delta = (@first + @amount) - @second
      return @delta == 0
    end

    chain :by do |amount|
      @amount = amount.to_i
    end

    failure_message do |actual|
      "value hasn't been increased by #{@amount}, before: #{@first}, after: #{@second}, delta: #{@delta}"
    end
  end
end