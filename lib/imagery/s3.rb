require "aws/s3"

class Imagery
  module S3
    def self.included(imagery)
      imagery.extend Config

      # Set the default host for amazon S3. You can also set this
      # to https://s3.amazon.com if you want to force secure connections
      # on a global scale.
      imagery.s3_host "http://s3.amazonaws.com"
    end

    module Config
      def s3_bucket(bucket = nil)
        @s3_bucket = bucket if bucket
        @s3_bucket
      end

      def s3_distribution_domain(domain = nil)
        @s3_distribution_domain = domain if domain
        @s3_distribution_domain
      end

      def s3_host(host = nil)
        @s3_host = host if host
        @s3_host
      end
    end

    # Convenience attribute which returns all size keys including `:original`.
    attr :keys

    def initialize(*args)
      super

      @keys = [@original] + sizes.keys
    end

    # If you specify a distribution domain (i.e. a cloudfront domain,
    # or even an S3 domain with a prefix), that distribution domain is
    # used.
    #
    # Otherwise the default canonical S3 url is used.
    def url(file = @original)
      if self.class.s3_distribution_domain
        "#{self.class.s3_distribution_domain}#{super}"
      else
        "#{self.class.s3_host}/#{self.class.s3_bucket}#{super}"
      end
    end

    # Returns the complete S3 id used for this object. The S3 id
    # is simply composed of the prefix and filename, e.g.
    #
    # - photos/1001/original.jpg
    # - photos/1001/small.jpg
    # - photos/1001/tiny.jpg
    #
    def s3_key(file)
      "#{prefix}/#{id}/#{ext(file)}"
    end

    # Deletes all keys defined for this object, which includes `:original`
    # and all keys in `sizes`.
    def delete
      super

      keys.each do |file|
        Gateway.delete(s3_key(file), self.class.s3_bucket)
      end
    end

    # Save the object as we normall would, but also upload all resulting
    # files to S3. We set the proper content type and Cache-Control setting
    # optimized for a cloudfront setup.
    def save(io, id = nil)
      super

      keys.each do |file|
        Gateway.store(s3_key(file),
          File.open(root(ext(file))),
          self.class.s3_bucket,
          :access => :public_read,
          :content_type => "image/jpeg",
          "Cache-Control" => "max-age=315360000"
        )
      end
    end

    # Provides a convenience wrapper around AWS::S3::S3Object and
    # serves as an auto-connect module.
    module Gateway
      def self.store(*args)
        execute(:store, *args)
      end

      def self.delete(*args)
        execute(:delete, *args)
      end

    private
      def self.execute(command, *args)
        begin
          AWS::S3::S3Object.__send__(command, *args)
        rescue AWS::S3::NoConnectionEstablished
          AWS::S3::Base.establish_connection!(
            :access_key_id     => ENV["AMAZON_ACCESS_KEY_ID"],
            :secret_access_key => ENV["AMAZON_SECRET_ACCESS_KEY"]
          )
          retry
        end
      end
    end
  end
end
