# frozen_string_literal: true

require_relative 'lib/ruby_gen_cli/version'

Gem::Specification.new do |spec|
  spec.name = 'ruby_gen_cli'
  spec.version = RubyGenCli::VERSION
  spec.authors = ['Ruby Gen CLI Team']
  spec.email = ['team@rubygeneric.com']

  spec.summary = 'A Ruby-based intelligent CLI tool for AI-powered development workflows'
  spec.description = <<~DESC
    Ruby Gen CLI is an intelligent command-line tool that brings AI-powered development 
    workflows to Ruby developers. Built with smart_prompt, smart_agent, and ruby_rich, 
    it provides conversational AI interaction, code generation, project analysis, and 
    streamlined development experiences directly from your terminal.
  DESC

  spec.homepage = 'https://github.com/ruby-gen-cli/ruby_gen_cli'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ruby-gen-cli/ruby_gen_cli'
  spec.metadata['changelog_uri'] = 'https://github.com/ruby-gen-cli/ruby_gen_cli/blob/main/CHANGELOG.md'
  spec.metadata['documentation_uri'] = 'https://github.com/ruby-gen-cli/ruby_gen_cli/wiki'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/ruby-gen-cli/ruby_gen_cli/issues'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Core dependencies
  spec.add_dependency 'thor', '~> 1.3'
  spec.add_dependency 'smart_prompt', '~> 0.1'
  spec.add_dependency 'smart_agent', '~> 0.1'
  spec.add_dependency 'ruby_rich', '~> 0.2'
  
  # Additional dependencies
  spec.add_dependency 'yaml', '~> 0.2'
  spec.add_dependency 'json', '~> 2.6'
  spec.add_dependency 'fileutils', '~> 1.7'
  spec.add_dependency 'readline', '~> 0.0.4'

  # Development dependencies
  spec.add_development_dependency 'bundler', '~> 2.4'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.57'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.25'
end