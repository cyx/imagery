require "fileutils"
require "tempfile"

class Imagery
  VERSION = "0.2.2"

  autoload :S3,     "imagery/s3"
  autoload :Faking, "imagery/faking"
  autoload :Test,   "imagery/test"

  # Raised during Imagery#save if the image can't be recognized.
  InvalidImage = Class.new(StandardError)

  # Acts as a namespace, e.g. `photos`.
  attr :prefix

  # A unique id for the image.
  attr :key

  # A hash of name => tuple pairs. The name describes the size, e.g. `small`.
  #
  # - The first element if the tuple is the resize geometry.
  # - The second (optional) element describes the extent.
  #
  # @example
  #
  #     Imagery.new(:photos, "1001", tiny: ["90x90^", "90x90"])
  #
  # @see http://www.graphicsmagick.org/GraphicsMagick.html#details-geometry
  # @see http://www.graphicsmagick.org/GraphicsMagick.html#details-extent
  attr :sizes

  # In order to facilitate a plugin architecture, all overridable methods
  # are placed in the `Core` module. Imagery::S3 demonstrates overriding
  # in action.
  module Core
    def initialize(prefix, key = nil, sizes = {})
      @prefix   = prefix.to_s
      @key      = key.to_s
      @sizes    = sizes
      @original = :original      # Used as the filename for the raw image.
      @ext      = :jpg           # We default to jpg for the image format.
    end

    # Returns the url for a given size, which defaults to `:original`.
    #
    # If the key is nil, a missing path is returned.
    def url(file = @original)
      return "/missing/#{prefix}/#{ext(file)}" if key.to_s.empty?

      "/#{prefix}/#{key}/#{ext(file)}"
    end

    # Accepts an `IO` object, typically taken from an input[type=file].
    #
    # The second optional `key` argument is used when you want to force
    # a new resource, useful in conjunction with cloudfront / high cache
    # scenarios where updating an existing image won't suffice.
    #
    # @example
    #   # Let's say we're in the context of a Sinatra handler,
    #   # and a file was submitted to params[:file]
    #
    #   post "upload" do
    #     im = Imagery.new(:avatar, current_user.id, thumb: ["20x20"])
    #     im.save(params[:file][:tempfile])
    #
    #     # At this point we have two files, original.jpg and thumb.jpg
    #
    #     { original: im.url, thumb: im.url(:thumb) }.to_json
    #   end
    #
    def save(io, key = nil)
      GM.identify(io) or raise(InvalidImage)

      # We delete the existing object iff:
      # 1. A key was passed
      # 2. The key passed is different from the existing key.
      delete if key && key != self.key

      # Now we can assign the new key passed, with the assurance that the
      # old key has been deleted and won't be used anymore.
      @key = key.to_s if key

      # Ensure that the path to all images is created.
      FileUtils.mkdir_p(root)

      # Write the original filename as binary using the `IO` object's data.
      File.open(root(ext(@original)), "wb") { |file| file.write(io.read) }

      # We resize the original raw image to different sizes which we
      # defined in the constructor. GraphicsMagick is assumed to exist
      # within the machine.
      sizes.each do |size, (resize, extent)|
        GM.convert root(ext(@original)), root(ext(size)), resize, extent
      end
    end

    # A very simple and destructive method. Deletes the entire folder
    # for the current prefix/key combination.
    def delete
      FileUtils.rm_rf(root)
    end
  end
  include Core

  # Returns the base filename together with the extension,
  # which defaults to jpg.
  def ext(file)
    "#{file}.#{@ext}"
  end

  def root(*args)
    self.class.root(prefix, key, *args)
  end

  def self.root(*args)
    File.join(@root, *args)
  end

  def self.root=(path)
    @root = path
  end
  self.root = File.join(Dir.pwd, "public")

  module GM
    # -size tells GM to only read from a given dimension.
    # -resize is the target dimension, and understands geometry strings.
    # -quality we force it to 80, which is very reasonable and practical.
    CONVERT = "gm convert -size '%s' '%s' -resize '%s' %s -quality 80 '%s'"

    # 2 is the file descriptor for stderr, which `gm identify`
    # happily chucks out information to, regardless if the image
    # was identified or not.
    #
    # We utilize the fact that gm identify exits with a status of 1 if
    # it fails to identify the image.
    #
    # @see for an explanation of file descriptions and redirection.
    #   http://stackoverflow.com/questions/818255/in-the-bash-shell-what-is-21
    IDENTIFY = "gm identify '%s' 2> /dev/null"

    def self.convert(src, dst, resize, extent = nil)
      system(sprintf(CONVERT, dim(resize), src, resize, extent(extent), dst))
    end

    def self.identify(io)
      file = Tempfile.new(["imagery", ".jpg"])

      # Something poorly documented, but vastly important: we need to
      # make sure the file is in binary mode.
      file.binmode

      # Now we can safely write the file knowing that we're operating in
      # binary mode.
      file.write(io.read)
      file.close

      `gm identify #{file.path} 2> /dev/null`

      return $?.success?
    ensure
      # Very important, else `io.read` will return "".
      io.rewind

      # Tempfile quickly runs out of names, so best to avoid that.
      file.unlink
    end

    # Return the cleaned dimension representation minus the
    # geometry directives.
    def self.dim(dim)
      dim.gsub(/\^><!/, "")
    end

    # Cropping and all that nice presentation kung-fu.
    #
    # @see http://www.graphicsmagick.org/GraphicsMagick.html#details-extent
    def self.extent(dim)
      if dim
        "-background black -compose Copy -gravity center -extent '#{dim}'"
      end
    end
  end
end
