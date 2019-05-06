require 'test_helper'

class TokenTest < ActiveSupport::TestCase
  test "checksum is removed from address on create" do
    token = Token.create({ :name => 'Test', :symbol => 'test', :address => '0xc50fEB05C839780596ef93a91b4B7E170B5C4A95' })
    assert_equal token.address, '0xc50feb05c839780596ef93a91b4b7e170b5c4a95'
  end
end
