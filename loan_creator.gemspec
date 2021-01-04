lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'loan_creator/version'

Gem::Specification.new do |spec|
  spec.name          = 'loan_creator'
  spec.version       = LoanCreator::VERSION
  spec.authors       = ["thibaulth", "nicob", "younes.serraj", "Antoine Becquet", "Jerome Drevet"]
  spec.email         = ['thibault@capsens.eu', 'nicolas.besnard@capsens.eu', 'younes.serraj@gmail.com', "antoine@capsens.eu", "jerome@capsens.eu"]

  spec.summary       = 'Create and update timetables from input data'
  spec.homepage      = 'https://github.com/CapSens/loan-creator'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.1.4'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.16'
  spec.add_development_dependency 'byebug', '~> 11.0'

  spec.add_runtime_dependency 'bigdecimal'
  spec.add_runtime_dependency 'activesupport'
end
