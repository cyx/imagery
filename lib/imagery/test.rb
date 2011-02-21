class Imagery
  module Test
    def self.included(base)
      Imagery.send :include, Imagery::Faking
      Imagery.mode = :fake
    end

  protected
    def imagery
      if ENV["REAL_IMAGERY"]
        Imagery.real { yield true }
      else
        Imagery.faked { yield false }
      end
    end
  end
end
