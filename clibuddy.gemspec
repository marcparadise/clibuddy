
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "clibuddy/version"

Gem::Specification.new do |spec|
  spec.name          = "clibuddy"
  spec.version       = Clibuddy::VERSION
  spec.authors       = ["Marc A. Paradise"]
  spec.email         = ["marc.paradise@gmail.com"]

  spec.summary       = %q{A CLI mocking tool.}
  spec.description   = %q{Define CLI prototypes in plain text and run them}
  #spec.homepage      = ""
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency("tty-spinner")
  spec.add_dependency("tty-screen")
  spec.add_dependency("tty-cursor")
  spec.add_dependency("tty-table")
  spec.add_dependency("pastel")

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-stack_explorer"
  spec.add_development_dependency "pry-byebug"
end
