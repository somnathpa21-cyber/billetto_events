
class Fact < RubyEventStore::Event
  class InvalidSchema < StandardError; end

  def self.strict(data:)
    normalized_data = validate_schema!(data)
    new(data: normalized_data)
  end

  def self.validate_schema!(data)
    schema = const_get(:SCHEMA, false)

    unless data.is_a?(Hash)
      raise InvalidSchema, "Event data must be a Hash"
    end

    normalized_data = data.transform_keys(&:to_sym)

    missing_keys = schema.keys - normalized_data.keys
    unknown_keys = normalized_data.keys - schema.keys

    unless missing_keys.empty? && unknown_keys.empty?
      raise InvalidSchema,
            "Missing keys: #{missing_keys}; unknown keys: #{unknown_keys}"
    end

    schema.each do |key, expected_type|
      value = normalized_data.fetch(key)

      unless value.is_a?(expected_type)
        raise InvalidSchema, "#{key} must be a #{expected_type}"
      end
    end

    normalized_data
  end

  def stream_names
    raise NotImplementedError,
          "#{self.class} must implement stream_names"
  end
end
