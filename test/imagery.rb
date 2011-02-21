require File.expand_path("helper", File.dirname(__FILE__))

test "defining with a prefix" do
  i = Imagery.new(:avatar)

  assert_equal "avatar", i.prefix
end

test "defining with a key" do
  i = Imagery.new(:avatar, "1001")

  assert_equal "avatar", i.prefix
  assert_equal "1001", i.key
end

test "defining with sizes" do
  i = Imagery.new(:avatar, "1001", small: ["100x100"])

  assert_equal "avatar", i.prefix
  assert_equal "1001", i.key
  assert_equal({ small: ["100x100"] }, i.sizes)
end

test "root defined to be Dir.pwd/public" do
  assert_equal File.join(Dir.pwd, "public"), Imagery.root
end

test "root accepts arguments" do
  assert_equal File.join(Dir.pwd, "public", "tmp"), Imagery.root("tmp")
end

test "allows override of the default Dir.pwd" do
  begin
    tmp = File.expand_path("tmp", File.dirname(__FILE__))

    Imagery.root = tmp
    assert_equal tmp, Imagery.root

  ensure
    Imagery.root = File.join(Dir.pwd, "public")
  end
end

test "url when missing key" do
  i = Imagery.new(:avatar)

  assert_equal "/missing/avatar/original.jpg", i.url
end

test "url with a key" do
  i = Imagery.new(:avatar, "1001")
  assert_equal "/avatar/1001/original.jpg", i.url
end

test "url with a key and a file" do
  i = Imagery.new(:avatar, "1001")
  assert_equal "/avatar/1001/small.jpg", i.url(:small)
end

# basic persistence
scope do
  setup do
    imagery = Imagery.new(:avatar, "1001")
    io = File.open(fixture("r8.jpg"), "rb")

    [imagery, io]
  end

  test "saving without any sizes defined" do |im, io|
    assert im.save(io)

    assert File.exist?(im.root("original.jpg"))
    assert_equal "1024x768", resolution(im.root("original.jpg"))
  end

  test "saving and specifying the key" do |im, io|
    assert im.save(io, "GUID")
    assert File.exist?(Imagery.root("avatar/GUID/original.jpg"))
  end

  test "saving with an already existing image" do |im, io|
    im.save(io)

    assert im.save(io, "GUID")
    assert File.exist?(Imagery.root("avatar/GUID/original.jpg"))
    assert ! File.exist?(Imagery.root("avatar/1001/original.jpg"))
  end
end

# basic resizing
scope do
  setup do
    imagery = Imagery.new(:avatar, 1, small: ["100x100"], tiny: ["30x30"])
    io = File.open(fixture("r8.jpg"), "rb")

    [imagery, io]
  end

  test "saves the different sizes" do |im, io|
    assert im.save(io)

    assert File.exist?(im.root("original.jpg"))
    assert File.exist?(im.root("small.jpg"))
    assert File.exist?(im.root("tiny.jpg"))

    assert_equal "1024x768", resolution(im.root("original.jpg"))

    # Since there was no extent or geometry specified, this will 
    # be resized by fitting the image proportionally within 100x100.
    assert_equal "100x75", resolution(im.root("small.jpg"))

    # Like small.jpg, it will be resized to fit within 30x30
    assert_equal "30x23", resolution(im.root("tiny.jpg"))
  end
end

# resizing with extent
scope do
  setup do
    imagery = Imagery.new(:avatar, 1, small: ["100x100^", "100x100"])
    io = File.open(fixture("r8.jpg"), "rb")

    [imagery, io]
  end

  test "saves an image maximized within the extent" do |im, io|
    im.save(io)

    assert_equal "100x100", resolution(im.root("small.jpg"))
  end
end
