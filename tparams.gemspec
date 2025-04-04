require_relative 'lib/tparams/version'

Gem::Specification.new do |spec|
  spec.name          = "tparams"
  spec.version       = TParams::VERSION
  spec.authors       = ["Dharmendra Verma"]
  spec.email         = ["dk@synaptic.com"]

  spec.summary       = %q{Parameter validation for Sorbet T::Struct objects}
  spec.description   = %q{TParams provides robust validation and type conversion for Rails controller parameters into T::Struct objects. It handles nested objects, arrays, enums, and primitive types with validation at each level.}
  spec.homepage      = "https://github.com/vy_labs/tparams"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob([
    "lib/**/*",
    "LICENSE",
    "README.md",
    "CHANGELOG.md",
  ])
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "sorbet-runtime", ">= 0.5.0"
  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "actionpack", ">= 6.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "sorbet", ">= 0.5.0"
end
