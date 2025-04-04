# typed: strict
module Errors
  # Error raised when validation fails for a T::Struct
  class ValidationError < StandardError
    extend T::Sig

    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :errors

    sig { params(errors: T::Hash[Symbol, T.untyped]).void }
    def initialize(errors)
      @errors = errors
      message = "Validation failed: #{errors.inspect}"
      super(message)
    end
  end

  # Error raised when casting between types fails
  class CastingError < StandardError
    extend T::Sig

    sig { params(message: String).void }
    def initialize(message)
      super(message)
    end
  end
end
