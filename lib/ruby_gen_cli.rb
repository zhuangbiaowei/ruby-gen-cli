# frozen_string_literal: true

require_relative 'ruby_gen_cli/version'
require_relative 'ruby_gen_cli/engine'
require_relative 'ruby_gen_cli/cli'
require_relative 'ruby_gen_cli/config_manager'
require_relative 'ruby_gen_cli/conversation'
require_relative 'ruby_gen_cli/context_processor'

# Load UI components
require_relative 'ruby_gen_cli/ui/console'
require_relative 'ruby_gen_cli/ui/progress'
require_relative 'ruby_gen_cli/ui/panels'

# Load agents (commented out until implemented)
# require_relative 'ruby_gen_cli/agents/base_agent'
# require_relative 'ruby_gen_cli/agents/code_generator'
# require_relative 'ruby_gen_cli/agents/chat_assistant'

# Load tools (commented out until implemented)
# require_relative 'ruby_gen_cli/tools/file_operations'
# require_relative 'ruby_gen_cli/tools/project_analyzer'
# require_relative 'ruby_gen_cli/tools/code_analysis'

# Main module for Ruby Gen CLI
module RubyGenCli
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class AgentError < Error; end
  class ToolError < Error; end

  # Default configuration
  DEFAULT_CONFIG = {
    default_llm: 'SiliconFlow',
    temperature: 0.7,
    max_tokens: 4000,
    streaming: true,
    theme: 'default',
    log_level: 'info'
  }.freeze

  class << self
    attr_accessor :config

    # Initialize the CLI system
    def configure
      @config = DEFAULT_CONFIG.dup
      yield(@config) if block_given?
      @config.freeze
    end

    # Get current configuration
    def configuration
      @config ||= DEFAULT_CONFIG
    end

    # Reset configuration to defaults
    def reset_configuration!
      @config = DEFAULT_CONFIG.dup
    end
  end
end