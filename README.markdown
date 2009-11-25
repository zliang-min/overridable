# Overridable

Overridable is a pure ruby library which helps you to make your methods which are defined in classes to be able to be overrided by mixed-in modules.

## Why?

Some people are overusing `alias_method_chain` in their codes like what wycats mentioned in [his post][post]. One of the reasons that people like using `alias_method_chain` is because it's impossible for modules to override methods that are defined in classes when they are included. For example:
    class Thing
      def foo
        'Thing.foo'
      end
    end
    
    module Extension
      def foo
        'Extension.foo'
      end
    end
    
    Thing.send :include, Extension
    Thing.new.foo #=> Thing.foo # not Extension.foo

In order to achieve that goal, some will write the Extension module like this:
    module Extension
      def foo_with_redef
        'Extension.foo'
      end
      # you can also do this by: alias_method_chain :foo, :redef, if you use ActiveSupport.
      alias foo_without_redef foo
      alias foo foo_with_redef
    end
    
    Thing.send :include, Extension
    Thing.new.foo #=> Extension.foo

But according to the [post][post], this is a bad practice. And *overridable* is a gem that provides a neat mean to resolve this problem.

## How?

There are two ways to do this with *overridable*: in class or in module.

### In class

Remember Thing and Extension in our first example? Let's make some changes:
    require 'overridable'
    
    Thing.class_eval {
      include Overridable
      overrides :foo
      
      include Extension
    }
    
    Thing.new.foo #=> Extension.foo
That's it! You can specify which methods can be overrided by `overrides` method. One more example based on the previous one:
    Thing.class_eval {
      def bar; 'Thing.bar' end
      def baz; 'Thing.baz' end
      def id;  'Thing'     end

      overrides :bar, :baz
    }
    
    Extension.module_eval {
      def bar; 'Extension.bar' end
      def baz; 'Extension baz' end
      def id;  'Extension'     end
    }
    
    thing = Thing.new
    thing.bar #=> 'Extension.bar'
    thing.baz #=> 'Extension.baz'
    thing.id  #=> 'Thing'
Of course it's not the end of our story ;) How could I call this *override* if we cannot use `super`? Go on with our example:
    Extension.module_eval {
      def bar
        parent = super
        me = 'Extension.bar'
        "I'm #{me} and I overrided #{parent}"
      end
    }

    Thing.new.bar => I'm Extension.bar and I overrided Thing.bar

### In module

If you have many methods in your module and find that it's too annoying to use `overrides`, then you can mix Overridable::ModuleMixin in your module. Example ( we all like examples, don't we? ):
    class Thing
      def method_one; ... end
      def method_two; ... end
      ...
      def method_n;   ... end
    end
    
    module Extension
      include Overridable::ModuleMixin
    
      def method_one; ... end
      def method_two; ... end
      ...
      def method_n;   ... end
    end

    Thing.send :include, Extension #=> method_one, method_two, ..., method_n are all overrided.

Since version 0.3.1, you can use `overrides` in your module to specify which method should be overrided and which should not. Let's rewrite the Extension module above:
    module Extension
      include Overridable::ModuleMixin
      overrides :only => [:method_one, :method_two]

      # define methods here...
    end
    
    Thing.send :include, Extension #=> only method_one and method_two will be overrided.

You can also use `overrides :except => [:method_one, :method_two]` to tell the module not to override method_one and method_two in the classes which include it.

## Install

    gem source -a http://gemcutter.org # you neednot do this if you have already had gemcutter in your source list
    gem install overridable

## Dependencies

* Ruby >= 1.8.7
* riot >= 0.10.0 just for test
* yard >= 0.4.0  just for generating document

## Test

    $> cd $GEM_HOME/gems/overridable-x.y.z
    $> rake test # requires riot

## TODO

These features **only** will be added when they are asked for.

* :all and :except for overrides 
      overrides :all, :except => [:whatever, :excepts]
* override with block    
      override :foo do |*args|
        super # or not
        # any other stuff
      end
* tell me what's missing.

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2009 梁智敏. See LICENSE for details.

[post]: http://yehudakatz.com/2009/03/06/alias_method_chain-in-models/
