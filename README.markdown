# Overridable

Overridable is a pure ruby library which helps you to make your methods which are defined in classes to be able to be overrided by mixed-in modules.

## Why?

We all know that it's impossible for modules to override methods that are defined in classes when they are included. For example:
    class Thing
      def foo
        'Thing.foo'
      end
    end
    
    module Redef
      def foo
        'Redef.foo'
      end
    end
    
    Thing.send :include, Redef
    Thing.new.foo #=> Thing.foo # not Redef.foo

Usually, in order to achieve that goal, we will write the Redef module like this:
    module Redef
      def foo_with_redef
        'Redef.foo'
      end
      # you can also do this by: alias_method_chain :foo, :redef, if you use ActiveSupport.
      alias foo_without_redef foo
      alias foo foo_with_redef
    end
    
    Thing.send :include, Redef
    Thing.new.foo #=> Redef.foo

So it will likely become a with/without hell in your code ( you can find dozens of such methods in Rails' code ). And *overridable* is a library that provides a neat mean to resolve this problem.

## How?

There are two ways to do this with *overridable*: in class or in module.

### In class

Remember Thing and Redef in our first example? Let's make some changes:
    require 'overridable'
    
    Thing.class_eval {
      include Overridable
      overrides :foo
      
      include Redef
    }
    
    Thing.new.foo #=> Redef.foo
That's it! You can specify which methods can be overrided by `overrides` method. One more example based on the previous one:
    Thing.class_eval {
      def bar; 'Thing.bar' end
      def baz; 'Thing.baz' end
      def id;  'Thing'     end

      overrides :bar, :baz
    }
    
    Redef.module_eval {
      def bar; 'Redef.bar' end
      def baz; 'Redef baz' end
      def id;  'Redef'     end
    }
    
    thing = Thing.new
    thing.bar #=> 'Redef.bar'
    thing.baz #=> 'Redef.baz'
    thing.id  #=> 'Thing'
Of course it's not the end of our story ;) How could I call this *override* if we cannot use `super`? Continue our example:
    Redef.module_eval {
      def bar
        parent = super
        me = 'Redef.bar'
        "I'm #{me} and I overrided #{parent}"
      end
    }

    Thing.new.bar => I'm Redef.bar and I overrided Thing.bar

### In module

If you have many methods in your module and find that it's too annoying to use `overrides`, then you can mix Overridable::ModuleMixin in your module. Example ( we all like examples, don't we? ):
    class Thing
      def method_one; ... end
      def method_two; ... end
      ...
      def method_n;   ... end
    end
    
    module Redef
      include Overridable::ModuleMixin
    
      def method_one; ... end
      def method_two; ... end
      ...
      def method_n;   ... end
    end

    Thing.send :include, Redef #=> method_one, method_two, ..., method_n are all overrided.

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
