require 'rubygems'
require 'riot'
require 'overridable'

# colorize is incompatible with Ruby 1.9 at this point
# and riot requires colorize
::PLATFORM = ::RUBY_PLATFORM unless defined?(::PLATFORM)
