# frozen_string_literal: true

require_relative 'ui/console'
require_relative 'ui/progress'
require_relative 'ui/panels'

# UI module with shared configuration
module RubyGenCli
  module UI
    # Check for ruby_rich availability once
    begin
      require 'ruby_rich'
      RUBY_RICH_AVAILABLE = true
    rescue LoadError
      RUBY_RICH_AVAILABLE = false
      puts "Warning: ruby_rich not available, using basic terminal output"
    end
    
    # Convenience method to create a console instance
    def self.new_console(config_manager)
      if RUBY_RICH_AVAILABLE
        RichConsole.new(config_manager)
      else
        BasicConsole.new(config_manager)
      end
    end
  end
end