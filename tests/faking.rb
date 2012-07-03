require File.expand_path("helper", File.dirname(__FILE__))
require "stringio"

# Imagery::Test hooks
scope do
  setup do
    Object.send :include, Imagery::Test
  end

  test "auto-includes Imagery::Faking upon inclusion" do
    assert Imagery.ancestors.include?(Imagery::Faking)
  end

  test "auto-sets mode to :fake" do
    assert_equal :fake, Imagery.mode
  end
end


class Imagery
  include Faking
end

test "skips saving when faked" do
  Imagery.mode = :fake

  i = Imagery.new(:avatar, "1001")
  i.save(StringIO.new)

  assert ! File.exist?(Imagery.root("avatar", "1001"))
end

test "skips deleting when faked" do
  Imagery.mode = :fake
  
  FileUtils.mkdir_p(Imagery.root("avatar", "1001"))

  i = Imagery.new(:avatar, "1001")
  i.delete

  assert File.exist?(Imagery.root("avatar", "1001"))
end

# Imagery::Test
scope do
  extend Imagery::Test

  test "yields true when REAL_IMAGERY is set" do
    ENV["REAL_IMAGERY"] = "true"
  
    enabled = nil

    imagery do |e|
      enabled = e  
    end

    assert enabled
  end

  test "yields false when REAL_IMAGERY is not set" do
    ENV["REAL_IMAGERY"] = nil
  
    enabled = nil

    imagery do |e|
      enabled = e  
    end

    assert_equal false, enabled
  end
end
