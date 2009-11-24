# Including this module in your class will give your class the ability to make its methods to be overridable by included modules. Let's look at some examples for easier understanding.
# @example
#   class Thing
#     def foo
#       puts 'Thing.foo'
#     end
#   end
#
#   module Foo
#     def foo
#       puts 'Foo.foo'
#     end
#   end
#
#   # If you don't use Overridable, you will get:
#   Thing.send :include, Foo
#   Thing.new.foo #=> print: Thing.foo\n
#
#   # If you use Overridable *before* you include the module, things will become to be:
#   Thing.class_eval {
#     include Overridable
#     overrides :foo # specifies which methods can be overrided.
#     include Foo
#   }
#   Thing.new.foo => print: Foo.foo\n
#
# You are not just limited to write a brandnew method, but also call the original method by `super`.
# @example
#   # Let's change the Foo module in the previous example:
#   module Foo
#     def foo
#       super
#       puts 'Foo.foo'
#     end
#   end
#
#   Thing.new.foo #=> print: Thing.foo\nFoo.foo\n
#
# Thanks to this feature, you don't need method chains any more! ;)
#
# You can also use Overridable::ModuleMixin to make things even a bit easier for some situations. See Overridable::ModuleMixin for details.
module Overridable

  # If your module includes this module, then classes which include your module
  # will make their methods which also defined in your module overridable.
  # Let's watch an example:
  # @example
  #   module YourModule
  #     include Overridable::ModuleMixin
  #
  #     def foo
  #       super
  #       puts "foo in your module"
  #     end
  #   end
  #
  #   class YourClass
  #     def foo
  #       puts "foo in your class"
  #     end
  #   end
  #
  #   YourClass.new.foo #=> print: foo in your class\n
  #
  #   YourClass.send :include, YourModule
  #
  #   YourClass.new.foo #=> print: foo in your class\nfoo in your module\n
  #
  # __NOTE__: If you need a custom `append_features` method in your module,
  # define that method before include this module in yours, or this is not
  # going to work.
  # @example
  #   module YourModule
  #     def self.append_features mod
  #       # things ...
  #     end
  #
  #     include Overridable::ModuleMixin
  #   end
  module ModuleMixin
    def self.append_features mod #:nodoc:
      class << mod
        include Overridable
        overrides :append_features
        include ClassMethods
      end
    end

    module ClassMethods
      def append_features mod #:nodoc:
        # these must be done in `append_features`, not `included`
        mod.send :include, Overridable
        mod.overrides *(
          public_instance_methods +
          protected_instance_methods +
          private_instance_methods
        )
        super
      end
    end
  end

  def self.included mod #:nodoc:
    mod.extend ClassMethods
  end

  module ClassMethods #:nodoc:
    # Specifies which methods can be overrided.
    # @param [Symbol,String] method_names specifies one or more methods which can be overrided.
    # @return nil
    def overrides *method_names
      return unless self.is_a?(Class) # do nothing if it's a module
      methods =
        method_names.map { |m| instance_method m rescue nil } \
                    .compact \
                    .select { |m| m.owner == self }
      unless methods.empty?
        # All overrided methods are defined in the same module
        is_module_defined =
          if method(:const_defined?).arity > 0 # 1.8.x
            self.const_defined?(:OverridedMethods)
          else # 1.9
            self.const_defined?(:OverridedMethods, false)
          end

        unless is_module_defined
          self.const_set(:OverridedMethods, Module.new)
          include self.const_get(:OverridedMethods)
        end
        mod = const_get(:OverridedMethods)

        old_verbose, $VERBOSE = $VERBOSE, nil # supress warnings
        methods.each { |m|
          remove_method m.name
          mod.send :define_method, m.name do |*args, &blk|
            m.bind(self).call(*args, &blk)
          end
        }
        $VERBOSE = old_verbose

        nil
      end
    end
  end

end
