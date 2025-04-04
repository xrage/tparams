# typed: strict

module Errors
  # Error raised when validation fails for a T::Struct
  class ValidationError < StandardError
    extend T::Sig

    sig { params(errors: T.any(String, T::Hash[T.untyped, T.untyped])).void }
    def initialize(errors)
      @_errors = errors
      super(format_errors(errors))
    end

    sig { returns(T.any(String, T::Hash[T.untyped, T.untyped])) }
    def errors
      build_error_response
    end

    private

    sig { params(errors: T.any(String, T::Hash[T.untyped, T.untyped])).returns(String) }
    def format_errors(errors)
      return errors if errors.is_a?(String)

      # Convert hash of errors to readable format
      errors.inspect
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def build_error_response
      errors_hash = { message: 'bad_request' }
      if @_errors.is_a?(String)
        errors_hash[:message] = message
      else
        errors_hash[:details] = @_errors
      end
      errors_hash
    end
  end

  # Error raised when casting between types fails
  class CastingError < StandardError
  end
end
