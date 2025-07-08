# frozen_string_literal: true

require 'smart_prompt'
begin
  require 'smart_agent'
  SMART_AGENT_AVAILABLE = true
rescue LoadError
  SMART_AGENT_AVAILABLE = false
  puts "Warning: smart_agent not available, some features may be limited"
end
require 'logger'

module RubyGenCli
  # Core engine that orchestrates all components
  class Engine
    attr_reader :config_manager, :smart_prompt_engine, :smart_agent_engine, 
                :conversation, :context_processor, :logger

    def initialize(config_path = nil)
      @config_manager = ConfigManager.new(config_path)
      @logger = setup_logger
      
      initialize_smart_components
      initialize_conversation_and_context
      
      @logger.info "Ruby Gen CLI Engine initialized successfully"
    end

    # Get SmartPrompt engine configured with current settings
    def prompt_engine
      @smart_prompt_engine ||= SmartPrompt::Engine.new(llm_config_path)
    end

    # Get SmartAgent engine configured with current settings  
    def agent_engine
      return nil unless SMART_AGENT_AVAILABLE
      @smart_agent_engine ||= SmartAgent::Engine.new(agent_config_path)
    end

    # Execute a worker using SmartPrompt
    def call_worker(worker_name, params = {})
      @logger.debug "Calling worker: #{worker_name} with params: #{params}"
      
      begin
        result = prompt_engine.call_worker(worker_name, params)
        @logger.debug "Worker #{worker_name} completed successfully"
        result
      rescue StandardError => e
        @logger.error "Worker #{worker_name} failed: #{e.message}"
        raise AgentError, "Worker execution failed: #{e.message}"
      end
    end

    # Execute a worker with streaming support
    def call_worker_with_stream(worker_name, params = {}, &block)
      @logger.debug "Calling streaming worker: #{worker_name}"
      
      begin
        prompt_engine.call_worker_by_stream(worker_name, params, &block)
      rescue StandardError => e
        @logger.error "Streaming worker #{worker_name} failed: #{e.message}"
        raise AgentError, "Streaming worker execution failed: #{e.message}"
      end
    end

    # Build and configure an agent
    def build_agent(agent_name, options = {})
      unless SMART_AGENT_AVAILABLE
        @logger.warn "SmartAgent not available, returning nil"
        return nil
      end
      
      @logger.debug "Building agent: #{agent_name} with options: #{options}"
      
      begin
        agent = agent_engine.build_agent(
          agent_name,
          tools: options[:tools] || [],
          mcp_servers: options[:mcp_servers] || []
        )
        
        # Configure agent with conversation context
        agent.instance_variable_set(:@conversation, @conversation)
        agent.instance_variable_set(:@context_processor, @context_processor)
        
        @logger.debug "Agent #{agent_name} built successfully"
        agent
      rescue StandardError => e
        @logger.error "Agent building failed: #{e.message}"
        raise AgentError, "Agent building failed: #{e.message}"
      end
    end

    # Get current configuration
    def config
      @config_manager
    end

    # Initialize or create configuration files
    def setup_configuration!
      unless @config_manager.config_exists?
        @logger.info "Creating default configuration files"
        @config_manager.initialize_config!
        create_default_templates
        create_default_workers
        create_default_agents
      end
    end

    # Reload configuration
    def reload_config!
      @logger.info "Reloading configuration"
      @config_manager.load_configurations
      reinitialize_engines
    end

    # Check system health
    def health_check
      issues = []
      
      # Check configuration
      issues << "Configuration directory not found" unless Dir.exist?(@config_manager.config_dir)
      
      # Check LLM connectivity
      begin
        test_llm_connection
      rescue StandardError => e
        issues << "LLM connection failed: #{e.message}"
      end
      
      # Check and create required directories
      %w[templates workers agents tools].each do |dir|
        path = @config_manager.get("paths.#{dir}")
        unless Dir.exist?(path)
          begin
            FileUtils.mkdir_p(path)
            @logger.info "Created #{dir} directory: #{path}"
          rescue StandardError => e
            issues << "Failed to create #{dir} directory: #{e.message}"
          end
        end
      end
      
      {
        healthy: issues.empty?,
        issues: issues,
        version: RubyGenCli::VERSION,
        config_path: @config_manager.config_dir
      }
    end

    private

    def initialize_smart_components
      setup_smart_prompt_engine
      setup_smart_agent_engine
    end

    def initialize_conversation_and_context
      @conversation = Conversation.new(@config_manager)
      @context_processor = ContextProcessor.new(@config_manager)
    end

    def setup_logger
      log_level = @config_manager.get('log_level', 'info').upcase
      logger = Logger.new(STDOUT)
      logger.level = Logger.const_get(log_level)
      logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
      end
      logger
    end

    def setup_smart_prompt_engine
      config_path = llm_config_path
      @smart_prompt_engine = SmartPrompt::Engine.new(config_path) if File.exist?(config_path)
    rescue StandardError => e
      @logger.warn "Failed to initialize SmartPrompt engine: #{e.message}"
    end

    def setup_smart_agent_engine
      return unless SMART_AGENT_AVAILABLE
      
      config_path = agent_config_path
      @smart_agent_engine = SmartAgent::Engine.new(config_path) if File.exist?(config_path)
    rescue StandardError => e
      @logger.warn "Failed to initialize SmartAgent engine: #{e.message}"
    end

    def llm_config_path
      File.join(@config_manager.config_dir, 'llm_config.yml')
    end

    def agent_config_path
      File.join(@config_manager.config_dir, 'agent_config.yml')
    end

    def reinitialize_engines
      @smart_prompt_engine = nil
      @smart_agent_engine = nil
      initialize_smart_components
    end

    def test_llm_connection
      # Simple test to verify LLM connectivity
      return unless @smart_prompt_engine

      @smart_prompt_engine.call_worker(:health_check, { text: "test" })
    rescue StandardError
      # Expected if health_check worker doesn't exist
      nil
    end

    def create_default_templates
      templates_dir = @config_manager.get('paths.templates')
      FileUtils.mkdir_p(templates_dir)
      
      # Create system prompt template
      system_template = File.join(templates_dir, 'system_prompt.erb')
      File.write(system_template, default_system_template) unless File.exist?(system_template)
      
      # Create chat template
      chat_template = File.join(templates_dir, 'chat.erb')
      File.write(chat_template, default_chat_template) unless File.exist?(chat_template)
    end

    def create_default_workers
      workers_dir = @config_manager.get('paths.workers')
      FileUtils.mkdir_p(workers_dir)
      
      # Create chat worker
      chat_worker = File.join(workers_dir, 'chat_worker.rb')
      File.write(chat_worker, default_chat_worker) unless File.exist?(chat_worker)
    end

    def create_default_agents
      # Create agent configuration file
      agent_config = {
        'logger_file' => './logs/agent.log',
        'engine_config' => llm_config_path,
        'agent_path' => @config_manager.get('paths.agents'),
        'tools_path' => File.join(@config_manager.get('paths.tools')),
        'mcp_path' => './mcps'
      }
      
      File.write(agent_config_path, agent_config.to_yaml)
    end

    def default_system_template
      <<~TEMPLATE
        You are Ruby Gen CLI, an intelligent development assistant built with Ruby.
        
        Your capabilities include:
        - Analyzing and understanding code repositories
        - Generating high-quality code in multiple languages
        - Providing development guidance and best practices
        - Helping with debugging and optimization
        - Creating documentation and tests
        
        Current context: <%= context || 'General development assistance' %>
        Working directory: <%= Dir.pwd %>
        
        Please provide helpful, accurate, and actionable responses.
      TEMPLATE
    end

    def default_chat_template
      <<~TEMPLATE
        System: <%= system_message %>
        
        User: <%= user_message %>
        
        <% if context && !context.empty? %>
        Context: <%= context %>
        <% end %>
        
        Please respond helpfully to the user's message.
      TEMPLATE
    end

    def default_chat_worker
      <<~RUBY
        SmartPrompt.define_worker :chat do
          use config.default_llm
          sys_msg(template(:system_prompt, { context: params[:context] }))
          prompt(template(:chat, {
            system_message: params[:system_message] || "You are a helpful AI assistant",
            user_message: params[:message],
            context: params[:context]
          }))
          send_msg
        end
      RUBY
    end
  end
end