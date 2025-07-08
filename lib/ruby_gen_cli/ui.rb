# frozen_string_literal: true

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
  end
end