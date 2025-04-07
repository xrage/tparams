# frozen_string_literal: true

module TParams
  # Handles processing and validation of ActionController parameters
  # This ensures parameters are properly structured and permitted before conversion
  module ParameterProcessing
    # Get the permitted keys for a struct class
    # This creates a structure of keys that can be used with params.permit
    # Results are cached for performance.
    #
    # @param struct_class [Class] The T::Struct class
    # @return [Hash] A hash of permitted keys
    def permitted_keys(struct_class)
      # Use struct_class as cache key
      cache_key = struct_class.object_id

      # Return cached result if available
      return @_permitted_keys_cache[cache_key] if @_permitted_keys_cache.key?(cache_key)

      # Compute permitted keys
      result = compute_permitted_keys(struct_class)

      # Cache the result
      @_permitted_keys_cache[cache_key] = result
    end

    # Actual computation for permitted_keys (not cached)
    # @private
    def compute_permitted_keys(struct_class)
      struct_class.props.each_with_object({}) do |(key, prop_info), permitted|
        key_sym = key.to_sym
        type_category, type = classify_type(prop_info)

        case type_category
        when :array
          element_category, element_type = classify_type_object(type)
          permitted[key_sym] = if element_category == :struct
                                 [permitted_keys(element_type)]
                               else
                                 []
                               end
        when :struct
          permitted[key_sym] = permitted_keys(type)
        else
          permitted[key_sym] = nil
        end
      end
    end

    # Convert a hash of permitted keys to the nested array format required by ActionController
    # Optimized to minimize object creation
    #
    # @param hash [Hash] The permitted keys hash
    # @return [Array] The nested array format for params.permit
    def convert_hash_to_nested_array(hash)
      hash.map do |key, value|
        if value.is_a?(Array) && value.first.is_a?(Hash)
          { key => convert_hash_to_nested_array(value.first) }
        elsif value.is_a?(Array)
          { key => [] }
        else
          key # Just return the key symbol directly
        end
      end
    end

    # Build a safe params object that only includes permitted parameters
    #
    # @param params [ActionController::Parameters] The request parameters
    # @param struct_class [Class] The T::Struct class
    # @return [ActionController::Parameters] The permitted parameters
    def build_safe_params(params, struct_class)
      permitted = convert_hash_to_nested_array(permitted_keys(struct_class))
      params.permit(permitted)
    end

    # Get the permitted parameters for this struct class
    # Validates the parameters and raises an error if validation fails
    #
    # @param params [ActionController::Parameters] The request parameters
    # @return [ActionController::Parameters] The permitted parameters
    # @raise [Errors::ValidationError] If validation fails
    def permitted_params(params:)
      cleaned_params = build_safe_params(params, self)
      errors = validate_keys(cleaned_params, self)
      raise ::Errors::ValidationError, errors if errors.any?

      cleaned_params
    end

    # Set a nested error in an errors hash
    # This handles creating the proper nested structure for errors
    # Optimized to minimize hash creations
    #
    # @param errors [Hash] The errors hash
    # @param path [Array] The path to the error
    # @param messages [Array, Hash, String] The error messages
    def set_nested_error(errors, path, messages)
      return if messages.nil? || (messages.respond_to?(:empty?) && messages.empty?)

      current = errors
      # Create intermediate objects only if needed
      if path.size > 1
        path[0..-2].each do |key|
          current[key] ||= {}
          current = current[key]
        end
      end
      current[path.last] = messages
    end
  end
end
