# frozen_string_literal: true

require_relative 'errors'

# Handles casting between parameter values and their target types
class ParameterCaster
  # Cast a value to the target type
  # This is used for validating that a value can be cast to its expected type
  # and for actual conversion during object building
  #
  # @param value [Object] The value to cast
  # @param target_type [Class] The target type to cast to
  # @return [Object] The cast value
  # @raise [Errors::CastingError] If the value cannot be cast to the target type
  def cast_value(value, target_type)
    return value if value.nil?
    return value if value.is_a?(target_type)

    # Special handling for boolean types
    if [TrueClass, FalseClass].include?(target_type)
      # Consider TrueClass and FalseClass as interchangeable
      return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)

      return cast_to_boolean(value)
    end

    if target_type == Integer
      cast_to_integer(value)
    elsif target_type == Float
      cast_to_float(value)
    elsif target_type == String
      cast_to_string(value)
    elsif target_type == Date
      cast_to_date(value)
    elsif target_type == Time
      cast_to_time(value)
    elsif target_type == DateTime
      cast_to_datetime(value)
    elsif defined?(T::Enum) && target_type.ancestors.include?(T::Enum)
      cast_to_enum(value, target_type)
    else
      # For other types like Arrays, Hashes, etc.
      # If we got here and it's not the target type already,
      # then it's not castable
      raise ::Errors::CastingError, "Cannot cast #{value.class} to #{target_type}"
    end
  end

  private

  # Cast a value to Integer
  # @param value [Object] The value to cast
  # @return [Integer] The cast integer
  # @raise [Errors::CastingError] If the value cannot be cast to Integer
  def cast_to_integer(value)
    case value
    when Integer
      value
    when String
      begin
        Integer(value)
      rescue ArgumentError
        raise ::Errors::CastingError, "Cannot cast '#{value}' to Integer"
      end
    when Float
      value.to_i
    else
      raise ::Errors::CastingError, "Cannot cast #{value.class} to Integer"
    end
  end

  # Cast a value to Float
  # @param value [Object] The value to cast
  # @return [Float] The cast float
  # @raise [Errors::CastingError] If the value cannot be cast to Float
  def cast_to_float(value)
    case value
    when Float
      value
    when Integer
      value.to_f
    when String
      begin
        Float(value)
      rescue ArgumentError
        raise ::Errors::CastingError, "Cannot cast '#{value}' to Float"
      end
    else
      raise ::Errors::CastingError, "Cannot cast #{value.class} to Float"
    end
  end

  # Cast a value to String
  # @param value [Object] The value to cast
  # @return [String] The cast string
  def cast_to_string(value)
    value.to_s
  end

  # Cast a value to Boolean
  # @param value [Object] The value to cast
  # @return [Boolean] The cast boolean
  # @raise [Errors::CastingError] If the value cannot be cast to Boolean
  def cast_to_boolean(value)
    case value
    when TrueClass, FalseClass
      value
    when String
      case value.downcase
      when 'true', 't', 'yes', 'y', '1'
        true
      when 'false', 'f', 'no', 'n', '0'
        false
      else
        raise ::Errors::CastingError, "Cannot cast '#{value}' to Boolean"
      end
    when Integer
      value != 0
    else
      raise ::Errors::CastingError, "Cannot cast #{value.class} to Boolean"
    end
  end

  # Cast a value to Date
  # @param value [Object] The value to cast
  # @return [Date] The cast date
  # @raise [Errors::CastingError] If the value cannot be cast to Date
  def cast_to_date(value)
    case value
    when Date
      value
    when Time, DateTime
      value.to_date
    when String
      begin
        Date.parse(value)
      rescue ArgumentError
        raise ::Errors::CastingError, "Cannot cast '#{value}' to Date"
      end
    else
      raise ::Errors::CastingError, "Cannot cast #{value.class} to Date"
    end
  end

  # Cast a value to Time
  # @param value [Object] The value to cast
  # @return [Time] The cast time
  # @raise [Errors::CastingError] If the value cannot be cast to Time
  def cast_to_time(value)
    case value
    when Time
      value
    when Date
      value.to_time
    when DateTime
      value.to_time
    when String
      begin
        Time.parse(value)
      rescue ArgumentError
        raise ::Errors::CastingError, "Cannot cast '#{value}' to Time"
      end
    when Integer
      Time.at(value)
    else
      raise ::Errors::CastingError, "Cannot cast #{value.class} to Time"
    end
  end

  # Cast a value to DateTime
  # @param value [Object] The value to cast
  # @return [DateTime] The cast datetime
  # @raise [Errors::CastingError] If the value cannot be cast to DateTime
  def cast_to_datetime(value)
    case value
    when DateTime
      value
    when Time
      value.to_datetime
    when Date
      value.to_datetime
    when String
      begin
        DateTime.parse(value)
      rescue ArgumentError
        raise ::Errors::CastingError, "Cannot cast '#{value}' to DateTime"
      end
    when Integer
      Time.at(value).to_datetime
    else
      raise ::Errors::CastingError, "Cannot cast #{value.class} to DateTime"
    end
  end

  # Cast a value to T::Enum
  # @param value [Object] The value to cast
  # @param enum_class [Class] The T::Enum class to cast to
  # @return [T::Enum] The cast enum value
  # @raise [Errors::CastingError] If the value cannot be cast to the T::Enum
  def cast_to_enum(value, enum_class)
    case value
    when enum_class
      value
    when String, Integer
      begin
        enum_class.deserialize(value)
      rescue KeyError
        raise ::Errors::CastingError, "Cannot cast '#{value}' to #{enum_class}"
      end
    else
      raise ::Errors::CastingError, "Cannot cast #{value.class} to #{enum_class}"
    end
  end
end
