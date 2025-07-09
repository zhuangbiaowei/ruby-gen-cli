# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module RubyGenCli
  # Configuration manager for Ruby Gen CLI
  class ConfigManager
    DEFAULT_CONFIG_PATH = File.expand_path('~/.ruby_gen_cli')
    CONFIG_FILE = 'config.yml'
    LLM_CONFIG_FILE = 'llm_config.yml'

    attr_reader :config_dir, :user_config, :llm_config

    def initialize(config_dir = nil)
      @config_dir = config_dir || DEFAULT_CONFIG_PATH
      @user_config = {}
      @llm_config = {}
      
      ensure_config_directory
      load_configurations
    end

    # Load all configuration files
    def load_configurations
      load_user_config
      load_llm_config
      merge_with_defaults
      validate_config!
    end

    # Save current configuration
    def save_config!
      File.write(config_file_path, @user_config.to_yaml)
    end

    # Get configuration value
    def get(key, default = nil)
      keys = key.to_s.split('.')
      value = keys.reduce(@user_config) { |config, k| config&.dig(k) }
      value || default
    end

    # Set configuration value
    def set(key, value)
      keys = key.to_s.split('.')
      last_key = keys.pop
      target = keys.reduce(@user_config) { |config, k| config[k] ||= {} }
      target[last_key] = value
    end

    # Get LLM configuration
    def llm(name)
      @llm_config['llms']&.dig(name.to_s) || {}
    end

    # List available LLMs
    def available_llms
      @llm_config['llms']&.keys || []
    end

    # Get default LLM name
    def default_llm
      @llm_config['default_llm'] || @user_config['default_llm'] || 'SiliconFlow'
    end

    # Check if configuration exists
    def config_exists?
      File.exist?(config_file_path)
    end

    # Initialize configuration with default values
    def initialize_config!
      @user_config = default_user_config
      @llm_config = default_llm_config
      
      save_config!
      save_llm_config!
    end

    def ensure_config_directory
      FileUtils.mkdir_p(@config_dir) unless Dir.exist?(@config_dir)
    end

    private

    def config_file_path
      File.join(@config_dir, CONFIG_FILE)
    end

    def llm_config_file_path
      File.join(@config_dir, LLM_CONFIG_FILE)
    end

    def load_user_config
      return unless File.exist?(config_file_path)

      @user_config = YAML.load_file(config_file_path) || {}
    rescue Psych::SyntaxError => e
      raise ConfigurationError, "Invalid YAML in config file: #{e.message}"
    end

    def load_llm_config
      return unless File.exist?(llm_config_file_path)

      @llm_config = YAML.load_file(llm_config_file_path) || {}
    rescue Psych::SyntaxError => e
      raise ConfigurationError, "Invalid YAML in LLM config file: #{e.message}"
    end

    def merge_with_defaults
      @user_config = default_user_config.merge(@user_config)
      @llm_config = default_llm_config.merge(@llm_config)
    end

    def save_llm_config!
      File.write(llm_config_file_path, @llm_config.to_yaml)
    end
    
    def validate_config!
      # Check if we have at least one LLM configured
      llms = @llm_config['llms'] || {}
      if llms.empty?
        warn "Warning: No LLMs configured. Please configure at least one LLM provider."
        return false
      end
      
      default_llm_name = @llm_config['default_llm']
      if default_llm_name.nil? || !llms.key?(default_llm_name)
        warn "Warning: Default LLM '#{default_llm_name}' not found. Using first available LLM."
        @llm_config['default_llm'] = llms.keys.first
      end
      
      # Validate each LLM configuration
      llms.each do |name, llm_config|
        if llm_config['adapter'].nil?
          warn "Warning: LLM '#{name}' missing adapter configuration"
          next
        end
        
        if llm_config['url'].nil?
          warn "Warning: LLM '#{name}' missing URL configuration"
          next
        end
        
        # Check API key availability
        api_key = resolve_api_key(llm_config['api_key'])
        if name != 'ollama' && (api_key.nil? || api_key.empty? || api_key == 'test_key')
          warn "Warning: LLM '#{name}' has no valid API key. API calls will fail unless you set the required environment variable."
        end
      end
      
      true
    end
    
    def resolve_api_key(key_pattern)
      return nil if key_pattern.nil?
      
      # Handle environment variable patterns like "ENV['VAR_NAME']"
      if key_pattern.match?(/ENV\["(\w+)"\]/)
        env_var = key_pattern.match(/ENV\["(\w+)"\]/)[1]
        value = ENV[env_var]
        return value unless value.nil? || value.empty?
      end
      
      # Return the pattern as-is if it doesn't match expected format
      key_pattern
    end

    def default_user_config
      {
        'version' => RubyGenCli::VERSION,
        'default_llm' => 'SiliconFlow',
        'temperature' => 0.7,
        'max_tokens' => 4000,
        'streaming' => true,
        'theme' => 'default',
        'log_level' => 'info',
        'conversation_history_limit' => 50,
        'auto_save_conversations' => true,
        'ui' => {
          'color_scheme' => 'auto',
          'progress_style' => 'bar',
          'panel_style' => 'rounded'
        },
        'paths' => {
          'templates' => './templates',
          'workers' => './workers',
          'agents' => './agents',
          'tools' => './tools'
        }
      }
    end

    def default_llm_config
      {
        'adapters' => {
          'openai' => 'OpenAIAdapter'
        },
        'llms' => {
          'SiliconFlow' => {
            'adapter' => 'openai',
            'url' => 'https://api.siliconflow.cn/v1/',
            'api_key' => 'ENV["SILICONFLOW_API_KEY"]',
            'default_model' => 'Qwen/Qwen2.5-7B-Instruct'
          },
          'deepseek' => {
            'adapter' => 'openai',
            'url' => 'https://api.deepseek.com',
            'api_key' => 'ENV["DEEPSEEK_API_KEY"]',
            'default_model' => 'deepseek-reasoner'
          },
          'openai' => {
            'adapter' => 'openai',
            'url' => 'https://api.openai.com/v1/',
            'api_key' => 'ENV["OPENAI_API_KEY"]',
            'default_model' => 'gpt-4'
          },
          'ollama' => {
            'adapter' => 'openai',
            'url' => 'http://localhost:11434/',
            'default_model' => 'llama3.2'
          }
        },
        'default_llm' => 'SiliconFlow',
        'template_path' => './templates',
        'worker_path' => './workers',
        'logger_file' => './logs/ruby_gen_cli.log'
      }
    end
  end
end