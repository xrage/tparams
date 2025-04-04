# frozen_string_literal: true

module TParams
  # Handles property options for validation, like enum values and range constraints
  module PropertyOptions
    protected

    # Get the hash of property options defined for this class
    # @return [Hash<Symbol, Array>] The property options
    def property_options
      @property_options ||= {}
    end

    # Extended version of const that also handles options
    # @param name [Symbol] The constant name
    # @param type [Class] The type of the constant
    # @param kwargs [Hash] Additional arguments for const
    def const(name, type, **kwargs)
      property_options[name] = kwargs.delete(:options) if kwargs.key?(:options)

      # Clear caches when adding new props
      @_type_classification_cache = {}
      @_permitted_keys_cache = {}

      super
    end

    # Extended version of prop that also handles options
    # @param name [Symbol] The property name
    # @param type [Class] The type of the property
    # @param kwargs [Hash] Additional arguments for prop
    def prop(name, type, **kwargs)
      property_options[name] = kwargs.delete(:options) if kwargs.key?(:options)

      # Clear caches when adding new props
      @_type_classification_cache = {}
      @_permitted_keys_cache = {}

      super
    end

    # Get the options for a specific property
    # @param property_name [Symbol] The name of the property
    # @return [Array, nil] The options for the property or nil if not defined
    def options_for(property_name)
      options = property_options[property_name]
      return nil if options.nil?

      options.is_a?(Range) ? [options] : options
    end
  end
end
