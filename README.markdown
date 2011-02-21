Imagery
=======

## Image manipulation should be simple. It should be customizable. It should allow for flexibility. Imagery attempts to solve these.

### Imagery favors:

1. Simplicity and explicitness over magic DSLs.
2. OOP principles such as inheritance and composition.
3. Flexibility and extensibility.
4. Not being tied to any form of ORM.

1. Simplicity and Explicitness
------------------------------
To get started using Imagery you only need GraphicsMagick, ruby and Imagery of 
course.
    
    # on debian based systems
    sudo apt-get install graphicsmagick
    # or maybe using homebrew
    brew install graphicsmagick
    [sudo] gem install imagery

Then you may proceed using it.
  
    require 'rubygems'
    require 'imagery'

    i = Imagery.new(:photo, "1001", thumb: ["48x48^", "48x48"])
    i.save(File.open('/some/path/to/image.jpg'))

    File.exist?('public/photo/1001/thumb.jpg')
    # => true

    File.exist?('public/photo/1001/original.jpg')
    # => true

2. OOP Principles (that we already know)
----------------------------------------

### Ohm example (See [http://ohm.keyvalue.org](http://ohm.keyvalue.org))
    
    class User < Ohm::Model
      include Ohm::Callbacks
      
      after :save, :write_avatar

      def avatar=(fp)
        @avatar_fp = fp
      end

      def avatar
        Imagery.new :avatar, id, 
          :thumb => ["48x48^", "48x48"],
          :medium => ["120x120"]
      end

    protected
      def write_avatar
        avatar.save(@avatar_fp[:tempfile]) if @avatar_fp
      end
    end

    # Since we're using composition, we can customize the dimensions on an 
    # instance level.
    class Collage < Ohm::Model
      attribute :width
      attribute :height

      def photo
        Imagery.new :photo, id, :thumb => ["%sx%s" % [width, height]]
      end
    end
    
    # For cases where we want to use S3 for some and normal filesystem for others
    class S3Photo < Imagery
      include Imagery::S3

      s3_bucket "my-bucket"
    end

    # then maybe some other files are using cloudfront
    class CloudfrontPhoto < Imagery
      include Imagery::S3

      s3_bucket "my-bucket"
      s3_distribution_domain "assets.site.com"
    end

    # some might be using S3 EU, in which case you can specify the s3_host
    class CustomS3Host < Imagery::Model
      include Imagery::S3
      s3_host "http://my.custom.host"
      s3_bucket "my-bucket-name"
    end

3. Flexibility and Extensibility
--------------------------------
### Existing plugins: Faking and S3

#### Imagery::S3

As was shown in some examples above you can easily do S3 integration.
The access credentials are assumed to be stored in

    ENV["AMAZON_ACCESS_KEY_ID"]
    ENV["AMAZON_SECRET_ACCESS_KEY"]

you can do this by setting it on your .bash_profile / .bashrc or just
manually setting them somewhere in your appication

    ENV["AMAZON_ACCESS_KEY_ID"] = "_access_key_id_"
    ENV["AMAZON_SECRET_ACCESS_KEY"] = "_secret_access_key_"

Now you can just start using it:
  
    class Imagery
      include Imagery::S3
      s3_bucket "my-bucket"
    end

    i = Imagery.new :photo, 1001
    i.save(File.open("/some/path/to/image.jpg"))

#### Imagery::Faking

When doing testing, you definitely don't want to run image
resizing everytime. Enter Faking.

    # in your test_helper / spec_helper
    Imagery::Model.send :include, Imagery::Faking
    Imagery::Model.mode = :fake
  
    # but what if we want to run it for real on a case to case basis?
    # sure we can!
    Imagery::Model.real {
      # do some imagery testing here
    }

#### Imagery::Test

There is a module you can include in your test context to automate the pattern
of testing / faking on an opt-in basis.

    # in your test_helper / spec_helper
    class Test::Unit::TestCase
      include Imagery::Test
    end
    
    # now when you do some testing... (User assumes the user example above)
    imagery do |enabled|
      user = User.new(:avatar => { tempfile: File.open("avatar.jpg") })
      user.save

      if enabled
        assert File.exist?(user.avatar.root("original.jpg"))
      end
    end

Running your test suite:

    REAL_IMAGERY=true rake test

It's off by default though, so you don't have to do anything to make sure 
Imagery doesn't run.

### Extending Imagery
By making use of standard Ruby idioms, we can easily do lots with it. 
Exensibility is addressed via Ruby modules for example:

    class Imagery
      module MogileStore
        def self.included(base)
          class << base
            attr_accessor :mogile_config
          end
        end

        def save(io)
          if super
            # do some mogie FS stuff here
          end
        end

        def delete
          super
          # remove the mogile stuff here
        end
      end
    end

    # Now just include the module to use it.
    class Imagery
      include Imagery::MogileStore
      self.mogile_config = { :foo => :bar }
    end


### Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

### Copyright

Copyright (c) 2010 Cyril David. See LICENSE for details.
