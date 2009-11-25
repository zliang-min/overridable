require 'teststrap'

context "A module which includes Overridable::ModuleMixin has some methods defined in it." do
  setup {
    module SomeModule
      include Overridable::ModuleMixin

      def foo
        'SomeModule.foo'
      end

      protected
      def bar a
        super + 'SomeModule.bar'
      end

      private
      def baz
        super + 'SomeModule.baz'
      end
    end

    SomeModule
  }

  context "A class which has the same methods that are defined in that module," do
    setup {
      class SomeClass
        def foo
          'SomeClass.foo'
        end

        def bar a
          'SomeClass.bar'
        end

        def baz
          'SomeClass.baz'
        end
      end

      SomeClass
    }

    context "includes that module." do
      setup { topic.send :include, SomeModule; topic }

      asserts("foo should be overrided.") {
        topic.new.foo
      }.equals('SomeModule.foo')

      asserts("bar should be overrided.") {
        topic.new.send :bar, :whatever
      }.equals('SomeClass.bar' + 'SomeModule.bar')

      asserts("baz should be overrided.") {
        topic.new.send :baz
      }.equals('SomeClass.baz' + 'SomeModule.baz')
    end

    context "We specify which methods can be overrided." do
      setup {
        SomeModule.module_eval {
          overrides :only  => [:foo, :bar]
        }
        topic.send :include, SomeModule
        topic
      }

      asserts("foo should be overrided.") {
        topic.new.foo
      }.equals('SomeModule.foo')

      asserts("bar should be overrided.") {
        topic.new.send :bar, :whatever
      }.equals('SomeClass.bar' + 'SomeModule.bar')

      asserts("baz should not be overrided.") {
        topic.new.baz
      }.equals('SomeClass.baz')
    end

    context "We specify which methods cannot be overrided." do
      setup {
        SomeModule.module_eval {
          overrides :except  => :baz
        }
        topic.send :include, SomeModule
        topic
      }

      asserts("foo should be overrided.") {
        topic.new.foo
      }.equals('SomeModule.foo')

      asserts("bar should be overrided.") {
        topic.new.send :bar, :whatever
      }.equals('SomeClass.bar' + 'SomeModule.bar')

      asserts("baz should not be overrided.") {
        topic.new.baz
      }.equals('SomeClass.baz')
    end

    context "We specify both the whitelist and blacklist of to-be-overrided methods." do
      setup {
        SomeModule.module_eval {
          overrides :only => [:foo, :bar, :baz], :except  => :baz
        }
        topic.send :include, SomeModule
        topic
      }

      asserts("foo should be overrided.") {
        topic.new.foo
      }.equals('SomeModule.foo')

      asserts("bar should be overrided.") {
        topic.new.send :bar, :whatever
      }.equals('SomeClass.bar' + 'SomeModule.bar')

      asserts("baz should not be overrided.") {
        topic.new.baz
      }.equals('SomeClass.baz')
    end
  end
end
