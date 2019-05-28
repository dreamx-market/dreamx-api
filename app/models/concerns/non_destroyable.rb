module NonDestroyable
  extend ActiveSupport::Concern

  def destroy
    raise 'This record cannot be deleted'
  end

  def delete
    self.destroy
  end
end