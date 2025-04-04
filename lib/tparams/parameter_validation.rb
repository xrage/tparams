# typed: false

# ParameterValidation provides robust validation and type conversion for T::Struct objects
# It handles nested objects, arrays, enums, and primitive types with validation at each level
#
# Usage:
#   class MyDTO < T::Struct
#     extend ParameterValidation
#
#     prop :name, String
#     prop :age, Integer, options: (18..65)
#     prop :status, StatusEnum
#     prop :items, T::Array[ItemDTO]
#   end
#
#   # Create and validate from parameters
#   dto = MyDTO.build_from_params(params: params)
module ParameterValidation
  extend T::Sig

  # When a class extends this module, it gets all the functionality needed for validation
  # @param base [Class] The class extending this module
  sig { params(base: T.class_of(T::Struct)).void }
  def self.extended(base)
    base.extend(T::Sig)
    base.include(InstanceMethods)
    base.extend(PropertyOptions)
    base.extend(TypeClassification)
    base.extend(ParameterProcessing)
    base.extend(TypeValidation)
    base.extend(ObjectBuilder)

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
  sig { params(params: ActionController::Parameters).returns(T.untyped) }
  def build_from_params(params:)
    # Permit parameters only once
    cleaned_params = permitted_params(params:)

    # Convert parameters to valid objects and create the struct
    object = new(**convert_params_to_objects(cleaned_params))

    # Validate the object and all its nested properties
    errors = object.send(:perform_validation)
    raise ::Errors::ValidationError.new(errors) if errors.any?

    object
  end
end

# Load all component files
require_relative 'parameter_validation/property_options'
require_relative 'parameter_validation/type_classification'
require_relative 'parameter_validation/parameter_processing'
require_relative 'parameter_validation/type_validation'
require_relative 'parameter_validation/object_builder'
require_relative 'parameter_validation/instance_methods'
