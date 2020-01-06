module AccountNonEjectable
  extend ActiveSupport::Concern

  def account_must_not_be_ejected
    if self.account && self.account.ejected
      self.errors.add(:account, 'has been ejected')
    end
  end
end