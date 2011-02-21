require "fileutils"

class Imagery
  VERSION = "0.1.0"

  autoload :S3,     "imagery/s3"
  autoload :Faking, "imagery/faking"
  autoload :Test,   "imagery/test"
  
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
  # are placed in the `Core` module. Imagery::S3 demonstrates this overriding
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
  
    # Accepts an `IO` object, typically taken from a input[type=file].
    # 
    # The second optional `key` argument is used when you want to force
    # a new resource, useful in conjunction with cloudfront / high cache
    # scenarios where updating an existing image won't suffice.
    def save(io, key = nil)
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

    def self.convert(src, dst, resize, extent = nil)
      system(sprintf(CONVERT, dim(resize), src, resize, extent(extent), dst))
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
