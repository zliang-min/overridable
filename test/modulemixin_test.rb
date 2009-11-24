require 'teststrap'

context "A module which includes Overridable::ModuleMixin has some methods defined in it." do
  setup {
    module SomeModule
      include Overridable::ModuleMixin

      def foo
        'SomeModule.foo'
      end

      def bar a
        super + 'SomeModule.bar'
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

        private
        def bar a
          'SomeClass.bar'
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
        #topic.new.send :bar, :whatever
        topic.new.bar :whatever
      }.equals('SomeClass.bar' + 'SomeModule.bar')
    end
  end
end
