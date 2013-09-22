require File.expand_path("helper", File.dirname(__FILE__))

test "autloads" do
  e = nil

  begin
    Imagery::S3
  rescue Exception => ex
    e = ex
  end

  assert e.nil?
end

class Imagery
  include S3

  s3_bucket "cdn.site.com"
end

test "changes url to an S3 hosted one" do
  i = Imagery.new(:avatar)

  expect = "http://s3.amazonaws.com/cdn.site.com/missing/avatar/original.jpg"
  assert_equal expect, i.url
end

test "allows an s3_host override" do
  begin
    Imagery.s3_host "https://foo.com"

    i = Imagery.new(:avatar)

    expect = "https://foo.com/cdn.site.com/missing/avatar/original.jpg"
    assert_equal expect, i.url
  ensure
    Imagery.s3_host "http://s3.amazonaws.com"
  end
end

test "allows a distribution domain for cloudfront hosted buckets" do
  begin
    Imagery.s3_distribution_domain "https://cdn.site.com"

    i = Imagery.new(:avatar)
    expect = "https://cdn.site.com/missing/avatar/original.jpg"
    assert_equal expect, i.url

    i = Imagery.new(:avatar, "1001")
    expect = "https://cdn.site.com/avatar/1001/original.jpg"
    assert_equal expect, i.url

  ensure
    Imagery.instance_variable_set(:@s3_distribution_domain, nil)
  end
end

# persisting in sandboxed Gateway
scope do
  setup do
    Imagery.s3_bucket "buck"

    im = Imagery.new(:avatar, "1001", small: ["100x100"], medium: ["200x200"])
    io = File.open(fixture("r8.jpg"), "rb")

    [im, io]
  end

  test "saves all sizes to S3" do |im, io|
    im.save(io)

    cmds = Imagery::S3::Gateway.commands

    assert_equal [:store, "avatar/1001/original.jpg", "buck"], cmds.shift
    assert_equal [:store, "avatar/1001/small.jpg", "buck"], cmds.shift
    assert_equal [:store, "avatar/1001/medium.jpg", "buck"], cmds.shift

    assert cmds.empty?
  end

  test "doesn't delete when passing same id" do |im, io|
    im.save(io, "1001")

    cmds = Imagery::S3::Gateway.commands

    assert_equal [:store, "avatar/1001/original.jpg", "buck"], cmds.shift
    assert_equal [:store, "avatar/1001/small.jpg", "buck"], cmds.shift
    assert_equal [:store, "avatar/1001/medium.jpg", "buck"], cmds.shift

    assert cmds.empty?
  end

  test "deletes when passing a different id" do |im, io|
    im.save(io, "1002")

    cmds = Imagery::S3::Gateway.commands

    assert_equal [:delete, "avatar/1001/original.jpg", "buck"], cmds.shift
    assert_equal [:delete, "avatar/1001/small.jpg", "buck"], cmds.shift
    assert_equal [:delete, "avatar/1001/medium.jpg", "buck"], cmds.shift


    assert_equal [:store, "avatar/1002/original.jpg", "buck"], cmds.shift
    assert_equal [:store, "avatar/1002/small.jpg", "buck"], cmds.shift
    assert_equal [:store, "avatar/1002/medium.jpg", "buck"], cmds.shift

    assert cmds.empty?
  end
end
