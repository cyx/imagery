Gem::Specification.new do |s|
  s.name              = "imagery"
  s.version           = "1.0.1"
  s.summary           = "Simple image resizing"
  s.description       = "Clean & light interface around GraphicsMagick."
  s.authors           = ["Cyril David"]
  s.email             = ["cyx@cyx.is"]
  s.homepage          = "http://github.com/cyx/imagery"

  s.files = Dir[
    "LICENSE",
    "README.markdown",
    "makefile",
    "lib/**/*.rb",
    "imagery.gemspec",
    "tests/*.rb"
  ]

  s.add_development_dependency "cutest"
  s.add_development_dependency "aws-s3"
end
