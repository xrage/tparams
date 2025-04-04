# TParams

TParams provides robust validation and type conversion for Rails controller parameters into Sorbet's T::Struct objects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tparams'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install tparams
```

## Usage

### Basic Usage

```ruby
require 'tparams'

# Create a DTO (Data Transfer Object) class
class UserDTO < T::Struct
  extend TParams

  prop :name, String
  prop :age, Integer
  prop :email, String
  prop :active, T::Boolean
end

# In your controller
class UsersController < ApplicationController
  def create
    # Validate and convert parameters
    user_dto = UserDTO.build_from_params(params: params)

    # Use the validated data
    user = User.new(
      name: user_dto.name,
      age: user_dto.age,
      email: user_dto.email,
      active: user_dto.active
    )

    if user.save
      render json: user
    else
      render json: { errors: user.errors }, status: :unprocessable_entity
    end
  end
end
```

### Nested Objects

TParams handles nested objects and arrays of objects:

```ruby
class AddressDTO < T::Struct
  extend TParams

  prop :street, String
  prop :city, String
  prop :zip_code, String
end

class UserDTO < T::Struct
  extend TParams

  prop :name, String
  prop :addresses, T::Array[AddressDTO]
end
```

### Validation Options

You can specify validation options for properties:

```ruby
class UserDTO < T::Struct
  extend TParams

  prop :name, String
  prop :age, Integer, options: (18..65)
  prop :role, String, options: ['admin', 'user', 'guest']
end
```

### Custom Validations

You can add custom validations:

```ruby
class UserDTO < T::Struct
  extend TParams

  prop :name, String
  prop :email, String

  def validate
    unless email&.include?('@')
      raise Errors::ValidationError.new(email: ['Invalid email format'])
    end
  end

  def name_valid?
    name&.length.to_i > 2
  end
end
```

## Features

- Type validation and conversion for primitive types (String, Integer, Float, Boolean, etc.)
- Support for nested T::Struct objects
- Support for arrays of objects
- Automatic conversion of parameters to appropriate types
- Custom validation methods
- Detailed error reporting
- Strong parameters integration

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/portfolioiq/tparams.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
