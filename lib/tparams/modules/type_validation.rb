# frozen_string_literal: true

module TParams
  # Handles validation of field values based on their types
  # This ensures that all values conform to their expected types
  module TypeValidation
    # Validate all the keys in a parameters hash against a struct class
    # Optimized to minimize object creation during validation
    #
    # @param params [Hash] The parameters to validate
    # @param struct_class [Class] The T::Struct class
    # @param path [Array] The current path for nested error reporting
    # @return [Hash] A hash of validation errors
    def validate_keys(params, struct_class, path = [])
      errors = {}
      caster = ParameterCaster.new

      struct_class.props.each do |key, prop_info|
        key_sym = key.to_sym
        value = params[key_sym]

        # Skip validation if not needed
        next if skip_validation?(value, prop_info)

        # Check for required fields - this is a fast path
        if required_field_missing?(value, prop_info)
          current_path = path + [key_sym]
          set_nested_error(errors, current_path, ['Field is required'])
          next
        end

        # Only do more expensive validation if there's a value
        next if value.nil?

        # Validate the value
        begin
          # Get type info (cached for performance)
          type_category, type = classify_type(prop_info)

          # Build path only when needed
          current_path = path + [key_sym]

          # Validate based on type
          validate_field_by_type(type_category, value, type, current_path, caster, errors)
        rescue ::Errors::CastingError
          set_nested_error(errors, current_path, ['Invalid value'])
        end
      end

      errors
    end

    # Validate a field based on its type category
    # Routes validation to the appropriate method based on type
    #
    # @param type_category [Symbol] The type category (:array, :struct, etc.)
    # @param value [Object] The value to validate
    # @param type [Class] The expected type
    # @param current_path [Array] The current path for nested error reporting
    # @param caster [ParameterCaster] The caster for type conversion
    # @param errors [Hash] The errors hash to populate
    def validate_field_by_type(type_category, value, type, current_path, caster, errors) # rubocop:disable Metrics/ParameterLists
      case type_category
      when :array
        validate_array(value, type, current_path, caster, errors)
      when :struct
        validate_struct(value, type, current_path, errors)
      else # :primitive, :simple, :enum
        validate_primitive(value, type, current_path, caster, errors)
      end
    end

    # Validate an array value
    # Ensures the value is an array and validates each element
    #
    # @param value [Object] The value to validate
    # @param type [Class] The expected element type
    # @param current_path [Array] The current path for nested error reporting
    # @param caster [ParameterCaster] The caster for type conversion
    # @param errors [Hash] The errors hash to populate
    def validate_array(value, type, current_path, caster, errors)
      unless value.is_a?(Array)
        set_nested_error(errors, current_path, ['Must be an array'])
        return
      end

      # Skip validation for empty arrays
      return if value.empty?

      array_errors = {}
      element_category, element_type = classify_type_object(type)

      value.each_with_index do |item, index|
        # Skip nil items
        next if item.nil?

        if element_category == :struct
          item_errors = validate_keys(item, element_type, [])
          array_errors[index] = item_errors unless item_errors.empty?
        else
          validate_array_item(item, element_type, index, caster, array_errors)
        end
      end

      set_nested_error(errors, current_path, array_errors) unless array_errors.empty?
    end

    # Validate a single array item
    #
    # @param item [Object] The item to validate
    # @param type [Class] The expected type
    # @param index [Integer] The index in the array
    # @param caster [ParameterCaster] The caster for type conversion
    # @param array_errors [Hash] The array errors hash to populate
    def validate_array_item(item, type, index, caster, array_errors)
      caster.cast_value(item, type)
    rescue CastingError => e
      array_errors[index] = [e.message]
    end

    # Validate a struct value
    #
    # @param value [Object] The value to validate
    # @param type [Class] The expected struct type
    # @param current_path [Array] The current path for nested error reporting
    # @param errors [Hash] The errors hash to populate
    def validate_struct(value, type, current_path, errors)
      nested_errors = validate_keys(value, type, [])
      set_nested_error(errors, current_path, nested_errors) unless nested_errors.empty?
    end

    # Validate a primitive value
    #
    # @param value [Object] The value to validate
    # @param type [Class] The expected type
    # @param current_path [Array] The current path for nested error reporting
    # @param caster [ParameterCaster] The caster for type conversion
    # @param errors [Hash] The errors hash to populate
    def validate_primitive(value, type, _current_path, caster, _errors)
      caster.cast_value(value, type)
    end
  end
end
