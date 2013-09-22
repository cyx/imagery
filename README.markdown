Imagery
=======

Simple image resizing module.

## Prerequisites

You should have graphicsmagick first:

```bash
# on debian based systems
$ sudo apt-get install graphicsmagick

# or maybe using homebrew
$ brew install graphicsmagick
```

## Installing

```bash
$ gem install imagery
```

## Usage

```ruby
require 'imagery'

# - 48x48^ is the geometry string. This means we're resizing
#   to a 48x48^ constrained image
# - 48x48 (second one) means we're cropping the image to an
#   extent of 48x48 pixels.
i = Imagery.new(:photo, "1001", thumb: ["48x48^", "48x48"])
i.save(File.open('/some/path/to/image.jpg'))

File.exist?('public/photo/1001/thumb.jpg')
# => true

File.exist?('public/photo/1001/original.jpg')
# => true
```

## Advanced Usage (S3)

For cases where we want to use S3 for some and normal filesystem for others.

```ruby
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
```

## Extending

You can check `Imagery::S3` to see an example of an extension.

## Copyright

Copyright (c) 2010 Cyril David. See LICENSE for details.
