# typed: false
require 'sorbet-runtime'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/blank'
require 'action_controller/metal/strong_parameters'

require_relative 'tparams/version'
require_relative 'tparams/errors'
require_relative 'tparams/parameter_caster'
require_relative 'tparams/parameter_validation'

module TParams
  # The main entry point for the TParams gem
  # Extend T::Struct with TParams to enable parameter validation
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

  def self.extended(base)
    base.extend(ParameterValidation)
  end
end
