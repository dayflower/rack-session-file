# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["ITO Nobuaki"]
  gem.email         = ["daydream.trippers@gmail.com"]
  gem.description   = %q{A rack-based session store on plain file system.}
  gem.summary       = %q{A rack-based session store on plain file system}
  gem.homepage      = ""

  gem.files         = [
    "rack-session-file.gemspec",
    "Gemfile",
    "LICENSE",
    "README.md",
    "Rakefile",
    "lib/rack-session-file.rb",
    "lib/rails-session-file.rb",
    "lib/rack/session/file.rb",
    "lib/rack/session/file/abstract.rb",
    "lib/rack/session/file/marshal.rb",
    "lib/rack/session/file/pstore.rb",
    "lib/rack/session/file/yaml.rb",
    "spec/common.rb",
    "spec/rack-session-file_spec.rb",
    "spec/rack-session-file-marshal_spec.rb",
    "spec/rack-session-file-pstore_spec.rb",
    "spec/rack-session-file-yaml_spec.rb",
    "spec/spec_helper.rb",
  ]

  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rack-session-file"
  gem.require_paths = ["lib"]
  gem.version       = '0.4.0'

  if gem.respond_to? :specification_version then
    gem.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      gem.add_runtime_dependency 'rack', '>= 1.1.0'
      gem.add_development_dependency 'rspec', '>= 1.2.9'
    else
      gem.add_dependency 'rack', '>= 1.1.0'
      gem.add_dependency 'rspec', '>= 1.2.9'
    end
  else
    gem.add_dependency 'rack', '>= 1.1.0'
    gem.add_dependency 'rspec', '>= 1.2.9'
  end
end
