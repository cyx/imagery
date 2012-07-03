$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))

require "cutest"
require "imagery"

def fixture(filename)
  File.expand_path("fixtures/#{filename}", File.dirname(__FILE__))
end

def resolution(file)
  `gm identify #{file}`[/(\d+x\d+)/, 1]
end

prepare do
  FileUtils.rm_rf(File.expand_path("../public", File.dirname(__FILE__)))
  Imagery::S3::Gateway.commands.clear
end

class Imagery
  module S3
    module Gateway
      def self.execute(command, *args)
        commands << [command, *args.select { |a| a.respond_to?(:to_str) }]
      end

      def self.commands
        @commands ||= []
      end
    end
  end
end
