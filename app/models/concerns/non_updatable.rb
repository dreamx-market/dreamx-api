module NonUpdatable
  extend ActiveSupport::Concern

  included do
    @@immutable_attrs = []

    def self.non_updatable_attrs *attrs
      @@immutable_attrs.concat attrs
    end

    def immutable_attributes_cannot_be_updated
      @@immutable_attrs.each do |attr|
        if self.changed.include?(attr.to_s)
          errors.add(attr, 'Is immutable')
        end
      end
    end

    def decrement!
      raise 'Method has been disabled'
    end

    def decrement_counter
      raise 'Method has been disabled'
    end

    def increment!
      raise 'Method has been disabled'
    end

    def increment_counter
      raise 'Method has been disabled'
    end

    def toggle!
      raise 'Method has been disabled'
    end

    def touch
      raise 'Method has been disabled'
    end

    def update_all
      raise 'Method has been disabled'
    end

    def update_attribute
      raise 'Method has been disabled'
    end

    def update_column
      raise 'Method has been disabled'
    end

    def update_columns
      raise 'Method has been disabled'
    end

    def update_counters
      raise 'Method has been disabled'
    end
  end
end