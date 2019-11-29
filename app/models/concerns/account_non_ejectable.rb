module AccountNonEjectable
  extend ActiveSupport::Concern

  def account_must_not_be_ejected
    if self.account && self.account.ejected
      errors.add(:account_address, 'has been ejected')
    end
  end
end