$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'action_args/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'action-args'
  s.version     = ActionArgs::VERSION
  s.authors     = ['Mark Wong-VanHaren']
  s.email       = ['markwvh@gmail.com']
  s.homepage    = 'https://github.com/marklar/action-args'
  s.summary     = "Ruby on Rails plugin.  DSL for parameter declarations for your controller actions."
  s.description = "For each controller action, declare your parameters -- i.e. what arguments you expect, their types, and how to validate them.  Then in your action code, access your arguments via params' evil twin args."

  s.files = Dir["{app,config,db,lib}/**/*", 'MIT-LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir["test/**/*"]

  s.add_dependency 'rails', '~> 4.0.1'

  s.add_development_dependency 'sqlite3'
end
