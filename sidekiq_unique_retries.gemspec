# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "sidekiq_unique_retries"
  spec.version       = "0.1.0"
  spec.authors       = ["Andriy Yanko"]
  spec.email         = ["andriy.yanko@railsware.com"]

  spec.summary       = %q{Uniqueness for Sidekiq Retries}
  spec.homepage      = "https://github.com/railsware/sidekiq_unique_retries"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", "~> 5.2"

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
end
