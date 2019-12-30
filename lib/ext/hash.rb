class Hash
  def convert_keys_to_underscore_symbols!
    self.transform_keys { |key| key.to_s.underscore }.deep_symbolize_keys!
  end
end