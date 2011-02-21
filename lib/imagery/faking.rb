class Imagery
  module Faking
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Allows you to define the current mode. The only special value here is
      # `:fake`. If the mode is :fake, then Imagery::Model#save and
      # Imagery::Model#delete will not actually run.
      #
      # @example
      #
      #   Photo = Class.new(Struct.new(:id))
      #
      #   i = Imagery.new(Photo.new(1001))
      #   i.root = '/tmp'
      #
      #   Imagery::Model.faked {
      #     assert i.save(File.open('/path/to/image.png'))
      #   }
      #
      # @see Imagery::Test
      #
      attr_accessor :mode

      # Switches the current mode to :fake.
      #
      # @example
      #   Imagery::Model.mode == nil
      #   # => true
      #
      #   Imagery::Model.faked {
      #     Imagery::Model.mode == :fake
      #     # => true
      #   }
      #
      #   Imagery::Model.mode = nil
      #   # => true
      #
      def faked
        @omode, @mode = @mode, :fake
        yield
      ensure
        @mode = @omode
      end

      # Switches the current mode to nil. Useful for forcing real saves
      # in your test.
      #
      # You should do this at least once in your project just to know
      # that all your Imagery::Model#save and Imagery::Model#delete
      # operations actually work.
      #
      # @example
      #   Imagery::Model.mode = :fake
      #
      #   Imagery::Model.faked {
      #     Imagery::Model.mode == nil
      #     # => true
      #   }
      #
      #   Imagery::Model.mode = :fake
      #   # => true
      #
      def real
        @omode, @mode = @mode, nil
        yield
      ensure
        @mode = @omode
      end
    end

    # Implement the stubbed version of save and skips actual operation
    # if Imagery::Model.mode == :fake
    def save(io, key = nil)
      return true if self.class.mode == :fake

      super
    end

    # Implement the stubbed version of save and skips actual operation
    # if Imagery::Model.mode == :fake
    def delete
      return true if self.class.mode == :fake

      super
    end
  end
end
