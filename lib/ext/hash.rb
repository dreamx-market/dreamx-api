class Hash
  def convert_keys_to_underscore_symbols!
    self.deep_transform_keys! { |key| key.to_s.underscore.to_sym }
  end
end