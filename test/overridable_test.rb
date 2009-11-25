require 'teststrap'

context "a classes with some methods defined in it" do
  setup {
    class Thing
      def no_arguments
        'This is Thing.'
      end

      def one_argument a
        a
      end

      def any_arguments *args
        args.join('-')
      end

      def with_block *args, &blk
        blk.call(*args)
      end

      def keep_unchanged
        'unchanged'
      end
    end

    Thing
  }

  context "includes a module which has the sames methods" do
    setup {
      module ModuleA
        def no_arguments
          'This is ModuleA.'
        end

        def one_argument a
          a * 10
        end

        def any_arguments *args
          args.join('_')
        end

        def with_block *args, &blk
          blk.call(*args.map! { |a| a * 10 })
        end

        def keep_unchanged
          'changed'
        end
      end

      topic.send :include, ModuleA
      topic
    }

    # If these tests fail, that means we don't need this library any more ;)
    asserts("no_arguments should not be overrided") { topic.new.no_arguments } \
      .equals('This is Thing.')
    asserts("one_argument should not be overrided") { topic.new.one_argument(10) } \
      .equals(10)
    asserts("any_arguments should not be overrided") { topic.new.any_arguments('a', 'b', 'c') } \
      .equals(%w[a b c].join('-'))
    asserts("with_block should not be overrided") { topic.new.with_block('a', 'b', 'c') { |*args| args.join('-') } } \
      .equals(%w[a b c].join('-'))
    asserts("keep_unchanged should not be overrided") { topic.new.keep_unchanged } \
      .equals('unchanged')
  end

  context "includes Overridable and specifies methods to be overrided," do
    setup {
      topic.class_eval {
        include Overridable
        overrides :no_arguments, :one_argument, :any_arguments, :with_block
      }

      topic
    }

    context "then includes a module which has the same methods" do
      setup {
        module ModuleB
          def no_arguments
            'This is ModuleB.'
          end

          def one_argument a
            a * 10
          end

          def any_arguments *args
            args.join('_')
          end

          def with_block *args, &blk
            blk.call(*args.map! { |a| a * 10 })
          end

          def keep_unchanged
            'changed'
          end
        end

        topic.send :include, ModuleB
        topic
      }

      asserts("no_arguments have been overrided") { topic.new.no_arguments } \
        .equals('This is ModuleB.')
      asserts("one_argument have been overrided") { topic.new.one_argument(10) } \
        .equals(10 * 10)
      asserts("any_arguments have been overrided") { topic.new.any_arguments('a', 'b', 'c') } \
        .equals(%w[a b c].join('_'))
      asserts("with_block have been overrided") { topic.new.with_block('a', 'b', 'c') { |*args| args.join('-') } } \
        .equals(%w[a b c].map! { |e| e * 10 }.join('-'))
      asserts("keep_unchanged should not be overrided") { topic.new.keep_unchanged } \
        .equals('unchanged')
    end

    context "then includes a module with the same methods which call super in their bodies." do
      setup {
        module ModuleC
          def no_arguments
            super +
            'This is ModuleC.'
          end

          def one_argument a
            super + 123
          end

          def any_arguments *args
            [super, args.join('_')].join('@')
          end

          def with_block *args, &blk
            super(*args.map! { |e| "|#{e}|" }, &blk)
          end

          def keep_unchanged
            super
            'changed'
          end
        end

        topic.send :include, ModuleC
        topic
      }

      asserts("no_arguments have been overrided and work properly.") { topic.new.no_arguments } \
        .equals('This is Thing.' + 'This is ModuleC.')
      asserts("one_argument have been overrided and work properly.") { topic.new.one_argument(10) } \
        .equals(10 + 123)
      asserts("any_arguments have been overrided and work properly.") { topic.new.any_arguments('a', 'b', 'c') } \
        .equals([%w[a b c].join('-'), %w[a b c].join('_')].join('@'))
      asserts("with_block have been overrided and work properly.") { topic.new.with_block('a', 'b', 'c') { |*args| args.join('-') } } \
        .equals(%w[a b c].map! { |e| "|#{e}|" }.join('-'))
      asserts("keep_unchanged should not be overrided") { topic.new.keep_unchanged } \
        .equals('unchanged')
    end
  end

  context "there are also some protected and private methods in it." do
    setup {
      topic.class_eval {
        protected
        def protected_method; end
        private
        def private_method; end
      }
      topic
    }

    context "Call overrides on these protected and private methods, it should not change their scope." do
      setup {
        topic.class_eval {
          include Overridable
          overrides :protected_method, :private_method
        }
        topic
      }

      should("raise exception when call protected_method outside the class.") {
        topic.new.protected_method
      }.raises(NoMethodError, /protected method `protected_method' called/)

      should("raise exception when call private_method outside the class.") {
        topic.new.private_method
      }.raises(NoMethodError, /private method `private_method' called/)
    end
  end

end
