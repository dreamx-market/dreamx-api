module NonDestroyable
  extend ActiveSupport::Concern

  included do
    class << self
      def delete_all
        raise 'Method has been disabled'
      end

      def destroy_all
        self.delete_all
      end
    end

    def destroy
      raise 'Method has been disabled'
    end

    def delete
      self.destroy
    end
  end
end