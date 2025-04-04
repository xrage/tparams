# frozen_string_literal: true


module TParams
  # Provides instance-level validation methods for T::Struct objects
  # These methods are included in each instance of the struct
  module InstanceMethods
    # Custom validation logic - override in subclasses
    # This is where custom validation rules can be implemented
    #
    # @return [void]
    def validate
      nil
    end

    protected

    # Perform full validation on this instance
    # Runs both custom validation and field-level validation
    #
    # @return [Hash] A hash of validation errors
    def perform_validation
      errors = {}
      begin
        validate
      rescue ::Errors::ValidationError => e
        errors[:base] = e.message
      end

      # Only run field validation if there are no base errors
      field_errors = object_field_validation
      errors.merge!(field_errors) if field_errors.any?

      errors
    end

    private

    # Validate all fields in this object
    # Handles nested validation for complex types
    #
    # @return [Hash] A hash of validation errors
    def object_field_validation
      errors = {}

      # Use instance variables directly to avoid method calls
      # instance_variable_get is faster than calling send
      self.class.props.each do |key, prop_info|
        key_sym = key.to_sym
        accessor_key = prop_info[:accessor_key]
        value = instance_variable_get(accessor_key)

        # Get field type classification (cached for performance)
        type_category, type = self.class.send(:classify_type, prop_info)

        # Validate based on type
        field_errors = validate_field_by_category(key_sym, value, type_category, type)
        errors.merge!(field_errors) if field_errors.any?

        # Check for custom validation methods
        custom_errors = validate_with_custom_method(key_sym)
        errors.merge!(custom_errors) if custom_errors.any?
      end

      errors
    end

    # Validate a field based on its category
    #
    # @param key_sym [Symbol] The field key
    # @param value [Object] The field value
    # @param type_category [Symbol] The type category
    # @param type [Class] The expected type
    # @return [Hash] A hash of validation errors
    def validate_field_by_category(key_sym, value, type_category, type)
      # Fast path for nil values
      return {} if value.nil?

      case type_category
      when :array
        # Skip empty arrays
        return {} if value.empty?

        array_errors = validate_array_field(value, type)
        return { key_sym => array_errors } unless array_errors.empty?
      when :struct
        struct_errors = validate_struct_field(value)
        return { key_sym => struct_errors } if struct_errors.present?
      end

      {}
    end

    # Validate an array field
    # Validates each element in the array
    #
    # @param value [Object] The array value
    # @param type [Class] The expected element type
    # @return [Hash] A hash of validation errors
    def validate_array_field(value, type)
      # For arrays of structs or validatable objects
      return {} unless value.is_a?(Array)
      return {} if value.empty?

      array_errors = {}
      element_category, = self.class.send(:classify_type_object, type)

      if element_category == :struct
        value.each_with_index do |item, index|
          next if item.nil?

          # Check if the nested object has a perform_validation method
          next unless item.respond_to?(:perform_validation, true)

          begin
            item_errors = item.send(:perform_validation)
            array_errors[index] = item_errors if item_errors.present?
          rescue ::Errors::ValidationError => e
            array_errors[index] = e.message
          end
        end
      end

      array_errors
    end

    # Validate a struct field
    #
    # @param value [Object] The struct value
    # @return [Hash, String, nil] Validation errors or nil
    def validate_struct_field(value)
      # For nested struct objects
      if value&.respond_to?(:perform_validation, true)
        begin
          nested_errors = value.send(:perform_validation)
          return nested_errors if nested_errors.present?
        rescue ::Errors::ValidationError => e
          return e.message
        end
      end

      nil
    end

    # Validate with a custom validation method
    # Checks if a custom *_valid? method exists and calls it
    #
    # @param key_sym [Symbol] The field key
    # @return [Hash] A hash of validation errors
    def validate_with_custom_method(key_sym)
      field_errors = {}
      validation_method = "#{key_sym}_valid?"

      if respond_to?(validation_method)
        begin
          field_errors[key_sym] = 'Invalid value' unless send(validation_method)
        rescue ::Errors::ValidationError => e
          field_errors[key_sym] = e.message
        end
      end

      field_errors
    end
  end
end
