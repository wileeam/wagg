# encoding: utf-8

require_relative 'lib/wagg/version'

Gem::Specification.new do |spec|
  spec.name          = 'wagg'
  spec.version       = Wagg::VERSION
  spec.authors       = ['Guillermo Rodríguez Cano']
  spec.email         = ['wileeam@users.noreply.github.com']

  spec.summary       = %q{Write a short summary, because RubyGems requires one.}
  spec.description   = %q{Write a longer description or delete this line.}
  spec.homepage      = 'https://github.com/wileeam/wagg'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = File.join(spec.homepage, 'CHANGELOG.md')

  spec.add_dependency 'feedjira'
  spec.add_dependency 'httparty'
  spec.add_dependency 'mechanize', '~> 2.8.1'
  spec.add_dependency 'mini_racer'
  # spec.add_dependency 'nokogiri', '~> 1.10'

  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'minitest', '~> 5.14.4'
  spec.add_development_dependency 'rake', '~> 13.0.3'


  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
