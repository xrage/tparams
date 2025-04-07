# frozen_string_literal: true

module TParams
  # Handles conversion of validated parameters to object instances
  # This creates properly typed objects from raw parameter values
  module ObjectBuilder
    # Convert parameters to objects based on their types
    # Creates a hash of properly typed values for creating a struct
    #
    # @param params [Hash] The validated parameters
    # @return [Hash] A hash of converted values
    def convert_params_to_objects(params)
      converted_params = {}

      props.each do |key, prop_info|
        key_sym = key.to_sym
        next unless params.key?(key_sym)

        value = params[key_sym]
        next if value.nil?

        type_category, type = classify_type(prop_info)
        converted_params[key_sym] = convert_value_by_type(type_category, value, type, prop_info)
      end

      converted_params
    end

    # Convert a value based on its type category
    # Routes conversion to the appropriate method based on type
    #
    # @param type_category [Symbol] The type category (:array, :struct, :enum, etc.)
    # @param value [Object] The value to convert
    # @param type [Class] The target type
    # @param prop_info [Hash] The property information
    # @return [Object] The converted value
    def convert_value_by_type(type_category, value, type, _prop_info)
      case type_category
      when :array
        convert_array_value(value, type)
      when :struct
        convert_struct_value(value, type)
      when :enum
        convert_enum_value(value, type)
      else # :primitive, :simple
        value
      end
    end

    # Convert an array value
    # Creates an array of properly typed elements
    #
    # @param value [Object] The value to convert
    # @param element_type [Class] The expected element type
    # @return [Array] The converted array
    def convert_array_value(value, element_type)
      return [] unless value.is_a?(Array)
      return [] if value.empty?

      element_category, actual_type = classify_type_object(element_type)
      value.map do |item|
        next nil if item.nil?

        convert_value_by_type(element_category, item, actual_type, nil)
      end
    end

    # Convert a value to a struct
    # Creates a nested struct instance
    #
    # @param value [Object] The value to convert
    # @param type [Class] The target struct type
    # @return [T::Struct, nil] The converted struct or nil
    def convert_struct_value(value, type)
      return nil if value.nil?
      return value if value.is_a?(type)
      return nil unless value.is_a?(Hash) || value.is_a?(ActionController::Parameters)

      # Convert to symbolized hash
      params_hash = if value.is_a?(ActionController::Parameters)
                      value.to_unsafe_h.symbolize_keys
                    else
                      value.symbolize_keys
                    end

      # Build converted parameters
      converted_params = build_converted_params(params_hash, type)

      # Create and return the struct instance
      type.new(**converted_params)
    end

    private

    # Extract nested parameter conversion to a separate method
    def build_converted_params(params_hash, struct_type)
      converted_params = {}

      struct_type.props.each do |key, prop_info|
        key_sym = key.to_sym
        next unless params_hash.key?(key_sym)

        param_value = params_hash[key_sym]
        next if param_value.nil?

        type_category, nested_type = classify_type(prop_info)
        converted_params[key_sym] = convert_value_by_type(type_category, param_value, nested_type, prop_info)
      end

      converted_params
    end

    # Convert a value to an enum
    #
    # @param value [Object] The value to convert
    # @param type [Class] The target enum type
    # @return [Object, nil] The converted enum value or nil
    def convert_enum_value(value, type)
      return nil if value.nil?

      begin
        type.deserialize(value)
      rescue StandardError
        value # Return as is if can't deserialize
      end
    end
  end
end
