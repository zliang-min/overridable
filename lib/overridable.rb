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

        methods =
          if @override_options && !@override_options[:only].empty?
              @override_options[:only]
          else
            all_methods = 
              public_instance_methods +
              protected_instance_methods +
              private_instance_methods

            if @override_options && !@override_options[:except].empty?
              all_methods - @override_options[:except]
            else
              all_methods
            end
          end

        mod.overrides *methods
        super
      end

      # Whitelist and blacklist for to-be-overrided methods.
      # If this method with the same options is called multiple times within the same module,
      # only the last call will work.
      # @param [Hash] options the options describe methods are to be or not to be overrided.
      # @option options [Symbol, Array<Symbol>] :only only methods specified in this option will be overrided.
      # @option options [Symbol, Array<Symbol>] :except methods specified in this option will not be overrided.
      # @example
      #   overrides :except => [:foo, :bar]
      #   overrides :except => :baz
      #   overrides :only => [:foo, :bar]
      def overrides options = {}
        raise ArgumentError, "Only :only and :except options are accepted." unless
          options.keys.all? { |k| [:only, :except].include? k }
        @override_options ||= {:only => [], :except => []}
        @override_options[:only] = [options[:only]].flatten.compact if options[:only]
        @override_options[:except] = [options[:except]].flatten.compact if options[:except]
        @override_options[:only] = @override_options[:only] - @override_options[:except]
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
          scope = private_instance_methods(false).include?(m.name) ?
            :private :
            protected_instance_methods(false).include?(m.name) ?
            :protected : :public
          remove_method m.name
          mod.send :define_method, m.name do |*args, &blk|
            m.bind(self).call(*args, &blk)
          end
          mod.send scope, m.name
        }
        $VERBOSE = old_verbose
      end

      nil
    end
  end

end
