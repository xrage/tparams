# frozen_string_literal: true

module TParams
  # Handles the classification and analysis of property types
  # This is the central type handling system that determines how to process each property
  module TypeClassification
    # Determine the type category and actual type of a property
    # Classifies types into :array, :struct, :enum, :simple, or :primitive
    # Results are cached for performance.
    #
    # @param prop_info [Hash] The property information from T::Struct
    # @return [Array<Symbol, Class>] A tuple of [type_category, actual_type]
    def classify_type(prop_info)
      # Use prop_info object_id as cache key
      cache_key = prop_info.object_id

      # Return cached result if available
      return @_type_classification_cache[cache_key] if @_type_classification_cache.key?(cache_key)

      # Compute classification
      result = compute_type_classification(prop_info)
      # Cache the result
      @_type_classification_cache[cache_key] = result
    end

    # Actual computation for classify_type (not cached)
    # @private
    def compute_type_classification(prop_info)
      type_object = prop_info[:type_object]

      if type_object.is_a?(T::Types::TypedArray)
        return :array, type_object.type
      elsif type_object.is_a?(T::Types::Simple)
        raw_type = type_object.raw_type
        if raw_type < T::Struct
          return :struct, raw_type
        elsif raw_type.respond_to?(:deserialize)
          return :enum, raw_type
        else
          return :simple, raw_type
        end
      elsif type_object.respond_to?(:types)
        # Handle union types (T.nilable)
        non_nil_type = type_object.types.find { |t| t.try(:raw_type) != NilClass }
        return classify_type_object(non_nil_type) if non_nil_type
      end

      # Default for primitives and unhandled types
      [:primitive, prop_info[:type]]
    end

    # Get classification from a type_object directly
    # Similar to classify_type but works with a type object instead of prop_info
    # Results are cached for performance.
    #
    # @param type_object [Object] The type object to classify
    # @return [Array<Symbol, Class>] A tuple of [type_category, actual_type]
    def classify_type_object(type_object)
      # Use type_object object_id as cache key
      cache_key = type_object.object_id

      # Return cached result if available
      return @_type_object_classification_cache[cache_key] if @_type_object_classification_cache.key?(cache_key)

      # Compute classification
      result = compute_type_object_classification(type_object)

      # Cache the result
      @_type_object_classification_cache[cache_key] = result
    end

    # Actual computation for classify_type_object (not cached)
    # @private
    def compute_type_object_classification(type_object)
      if type_object.is_a?(T::Types::TypedArray)
        return :array, type_object.type
      elsif type_object.is_a?(T::Types::Simple)
        raw_type = type_object.raw_type
        if raw_type < T::Struct
          return :struct, raw_type
        elsif raw_type.respond_to?(:deserialize)
          return :enum, raw_type
        else
          return :simple, raw_type
        end
      end

      # Default
      [:primitive, type_object]
    end

    # Extract the actual type from a prop_info for validation
    #
    # @param prop_info [Hash] The property information
    # @return [Class] The actual type for validation
    def extract_type(prop_info)
      _, type = classify_type(prop_info)
      type
    end

    # Check if validation can be skipped for this field
    # Validation can be skipped for nil values that are optional
    #
    # @param value [Object] The value to check
    # @param prop_info [Hash] The property information
    # @return [Boolean] True if validation can be skipped
    def skip_validation?(value, prop_info)
      value.nil? && (prop_info[:fully_optional] || !prop_info[:default].nil? || prop_info[:_tnilable])
    end

    # Check if a required field is missing
    # A field is required if it's not optional, has no default, and is not nilable
    #
    # @param value [Object] The value to check
    # @param prop_info [Hash] The property information
    # @return [Boolean] True if a required field is missing
    def required_field_missing?(value, prop_info)
      value.nil? && !prop_info[:fully_optional] && prop_info[:default].nil? && !prop_info[:_tnilable]
    end
  end
end
