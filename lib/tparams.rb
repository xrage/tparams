# frozen_string_literal: true

require 'sorbet-runtime'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/blank'
require 'action_controller/metal/strong_parameters'

require_relative 'tparams/version'
require_relative 'tparams/errors'
require_relative 'tparams/parameter_caster'

# TParams provides robust validation and type conversion for T::Struct objects
# It handles nested objects, arrays, enums, and primitive types with validation at each level
#
# Usage:
#   class MyDTO < T::Struct
#     extend TParams
#
#     prop :name, String
#     prop :age, Integer, options: (18..65)
#     prop :status, StatusEnum
#     prop :items, T::Array[ItemDTO]
#   end
#
#   # Create and validate from parameters
#   dto = MyDTO.build_from_params(params: params)
module TParams
  # Load all component files
  require_relative 'tparams/modules/instance_methods'
  require_relative 'tparams/modules/property_options'
  require_relative 'tparams/modules/type_classification'
  require_relative 'tparams/modules/parameter_processing'
  require_relative 'tparams/modules/type_validation'
  require_relative 'tparams/modules/object_builder'

  # When a class extends this module, it gets all the functionality needed for validation
  # @param base [Class] The class extending this module
  def self.extended(base)
    base.extend(T::Sig)
    base.include(TParams::InstanceMethods)
    base.extend(TParams::PropertyOptions)
    base.extend(TParams::TypeClassification)
    base.extend(TParams::ParameterProcessing)
    base.extend(TParams::TypeValidation)
    base.extend(TParams::ObjectBuilder)

    # Initialize caches
    base.instance_variable_set(:@_type_classification_cache, {})
    base.instance_variable_set(:@_type_object_classification_cache, {})
    base.instance_variable_set(:@_permitted_keys_cache, {})
  end

  # ==========================================================================
  # Main Entry Point
  # ==========================================================================

  # Create and validate a T::Struct object from ActionController parameters
  # This is the main entry point for creating objects from request parameters
  #
  # @param params [ActionController::Parameters] The request parameters
  # @return [T::Struct] The validated struct instance
  # @raise [Errors::ValidationError] If validation fails
  def build_from_params(params:)
    # Permit parameters only once
    cleaned_params = permitted_params(params: params)

    # Convert parameters to valid objects and create the struct
    object = new(**convert_params_to_objects(cleaned_params))

    # Validate the object and all its nested properties
    errors = object.send(:perform_validation)
    raise ::Errors::ValidationError, errors if errors.any?

    object
  end
end
