# frozen_string_literal: true

require 'thor'
require 'readline'

module RubyGenCli
  # Main CLI interface using Thor
  class Cli < Thor
    include Thor::Actions

    # Class-level configuration
    class_option :config, aliases: '-c', type: :string, 
                 desc: 'Configuration directory path'
    class_option :verbose, aliases: '-v', type: :boolean, default: false,
                 desc: 'Enable verbose output'
    class_option :debug, aliases: '-d', type: :boolean, default: false,
                 desc: 'Enable debug mode'

    def initialize(args = [], opts = {}, config = {})
      super
      setup_engine
      setup_ui
    end

    desc 'version', 'Show version information'
    def version
      @console.puts("Ruby Gen CLI version #{RubyGenCli::VERSION}", style: 'bold green')
      @console.puts("Built with Ruby #{RUBY_VERSION}")
    end

    desc 'init', 'Initialize Ruby Gen CLI configuration'
    option :force, aliases: '-f', type: :boolean, default: false,
           desc: 'Force initialization even if config exists'
    def init
      if @engine.config.config_exists? && !options[:force]
        @console.warning('Configuration already exists. Use --force to reinitialize.')
        return
      end

      @console.header('Initializing Ruby Gen CLI', level: 1)
      
      @progress.installation([
        'Creating configuration directories',
        'Setting up default configuration',
        'Creating templates and workers', 
        'Initializing smart components',
        'Testing LLM connectivity'
      ]) do |step, step_num|
        case step_num
        when 1
          @engine.config.ensure_config_directory
        when 2
          @engine.setup_configuration!
        when 3
          # Templates and workers are created by setup_configuration!
        when 4
          @engine.reload_config!
        when 5
          health = @engine.health_check
          raise Error, health[:issues].join(', ') unless health[:healthy]
        end
      end

      @console.success('Ruby Gen CLI initialized successfully!')
      @console.info("Configuration saved to: #{@engine.config.config_dir}")
    end

    desc 'chat [MESSAGE]', 'Start interactive chat or send a single message'
    option :stream, aliases: '-s', type: :boolean, default: true,
           desc: 'Enable streaming responses'
    option :context, aliases: '--ctx', type: :boolean, default: true,
           desc: 'Include project context'
    def chat(message = nil)
      if message
        # Single message mode
        send_single_message(message)
      else
        # Interactive mode
        start_interactive_chat
      end
    end

    desc 'ask MESSAGE', 'Ask a single question and get response'
    option :stream, aliases: '-s', type: :boolean, default: true,
           desc: 'Enable streaming responses'
    option :context, aliases: '--ctx', type: :boolean, default: true,
           desc: 'Include project context'
    def ask(message)
      send_single_message(message)
    end

    desc 'generate TYPE [DESCRIPTION]', 'Generate code or content'
    option :output, aliases: '-o', type: :string,
           desc: 'Output file path'
    option :language, aliases: '-l', type: :string, default: 'ruby',
           desc: 'Programming language'
    def generate(type, description = nil)
      unless description
        description = @console.ask("What would you like to generate?")
      end

      @console.loading("Generating #{type}")
      
      # Use code generation agent
      result = generate_content(type, description, options)
      
      if options[:output]
        File.write(options[:output], result)
        @console.success("Generated #{type} saved to #{options[:output]}")
      else
        @console.code(result, language: options[:language], title: "Generated #{type}")
      end
    end

    desc 'analyze [PATH]', 'Analyze project or file'
    option :depth, aliases: '-d', type: :numeric, default: 3,
           desc: 'Analysis depth'
    option :format, aliases: '-f', type: :string, default: 'panel',
           desc: 'Output format (panel, json, table)'
    def analyze(path = '.')
      @console.loading("Analyzing #{path}")
      
      analyzer = @engine.context_processor
      if File.directory?(path)
        analyzer.current_directory = File.expand_path(path)
        analyzer.refresh!
        
        display_project_analysis(analyzer.project_info, options[:format])
      else
        # Analyze single file
        content = File.read(path)
        analysis = analyze_file_content(content, File.extname(path))
        display_file_analysis(analysis, options[:format])
      end
    end

    # desc 'config', 'Manage configuration'
    # subcommand 'config', ConfigCommands

    # desc 'conversation', 'Manage conversations' 
    # subcommand 'conversation', ConversationCommands

    desc 'status', 'Show system status'
    def status
      health = @engine.health_check
      
      status_data = {
        version: RubyGenCli::VERSION,
        health: health[:healthy] ? 'Healthy' : 'Issues Found',
        config_path: health[:config_path],
        llm: @engine.config.default_llm,
        session: @engine.conversation.current_session_id
      }

      if health[:healthy]
        @panels.status(status_data)
      else
        @console.error("System Health Issues:")
        health[:issues].each { |issue| @console.puts("  • #{issue}") }
      end
    end

    desc 'dashboard', 'Show comprehensive dashboard'
    def dashboard
      # Collect dashboard data
      health = @engine.health_check
      project_info = @engine.context_processor.project_info
      conversation_stats = @engine.conversation.stats
      
      dashboard_data = {
        status: {
          health: health[:healthy] ? 'Healthy' : 'Issues',
          version: RubyGenCli::VERSION,
          config: File.basename(@engine.config.config_dir)
        },
        project: {
          name: project_info[:name],
          type: project_info[:type],
          files: project_info[:size_stats][:total_files]
        },
        conversation: {
          session: conversation_stats[:current_session],
          messages: conversation_stats[:total_messages],
          duration: conversation_stats[:session_duration]
        }
      }

      @panels.dashboard(dashboard_data)
    end

    desc 'help [COMMAND]', 'Show help information'
    def help(command = nil)
      if command
        super
      else
        show_comprehensive_help
      end
    end

    # Default command when no arguments provided
    default_task :interactive

    desc 'interactive', 'Start interactive mode', hide: true
    def interactive
      welcome_user
      start_interactive_chat
    end

    private

    def setup_engine
      config_path = options[:config]
      @engine = Engine.new(config_path)
      
      # Set debug/verbose modes
      if options[:debug]
        @engine.config.set('log_level', 'debug')
      elsif options[:verbose]
        @engine.config.set('log_level', 'info')
      end
    end

    def setup_ui
      @console = UI.new_console(@engine.config)
      @progress = UI::Progress.new(@engine.config)
      @panels = UI::Panels.new(@engine.config)
    end

    def welcome_user
      welcome_panel = @panels.welcome(version: RubyGenCli::VERSION)
      @console.rich_console.print(welcome_panel)
      
      # Show project context if available
      project_info = @engine.context_processor.project_info
      if project_info[:type] != 'General'
        project_panel = @panels.project_info(project_info)
        @console.rich_console.print(project_panel)
      end
    end

    def start_interactive_chat
      @console.puts("\n💬 Interactive Chat Mode")
      @console.puts("Type 'exit', 'quit', or press Ctrl+C to leave")
      @console.puts("Type 'help' for available commands")
      @console.separator

      loop do
        begin
          input = Readline.readline('🤖 You: ', true)
          break if input.nil? || %w[exit quit bye].include?(input.strip.downcase)
          
          next if input.strip.empty?
          
          # Handle special commands
          case input.strip.downcase
          when 'help'
            show_chat_help
          when 'status'
            invoke(:status)
          when 'clear'
            @console.clear
          when /^\/(\w+)(.*)$/
            handle_slash_command($1, $2.strip)
          else
            # Regular chat message
            process_chat_message(input.strip)
          end
          
        rescue Interrupt
          @console.puts("\n👋 Goodbye!")
          break
        rescue StandardError => e
          @console.error("Error: #{e.message}")
          @console.debug(e.backtrace.join("\n")) if options[:debug]
        end
      end
    end

    def send_single_message(message)
      process_chat_message(message)
    end

    def process_chat_message(message)
      # Add user message to conversation
      @engine.conversation.add_user_message(message)
      
      # Prepare context
      context_data = options[:context] ? @engine.context_processor.get_context : nil
      
      # Prepare parameters for the chat worker
      params = {
        message: message,
        context: context_data&.to_s,
        with_history: true
      }

      @console.puts("\n🤖 Assistant: ", style: 'bold cyan')
      
      if options[:stream]
        # Streaming response
        response_parts = []
        @engine.call_worker_with_stream(:chat, params) do |chunk, _bytesize|
          content = chunk.dig('choices', 0, 'delta', 'content')
          if content
            print content
            response_parts << content
          end
        end
        
        # Add complete response to conversation
        complete_response = response_parts.join
        @engine.conversation.add_assistant_message(complete_response)
        puts "\n"
      else
        # Non-streaming response
        result = @engine.call_worker(:chat, params)
        response = result.is_a?(Hash) ? result['content'] : result.to_s
        
        @console.puts(response)
        @engine.conversation.add_assistant_message(response)
      end
    end

    def generate_content(type, description, options)
      params = {
        type: type,
        description: description,
        language: options[:language],
        context: @engine.context_processor.get_context
      }

      result = @engine.call_worker(:code_generator, params)
      result.is_a?(Hash) ? result['content'] : result.to_s
    end

    def analyze_file_content(content, extension)
      params = {
        content: content,
        file_type: extension,
        analysis_type: 'comprehensive'
      }

      @engine.call_worker(:code_analyzer, params)
    end

    def display_project_analysis(project_info, format)
      case format.to_sym
      when :json
        @console.json(project_info)
      when :table
        # Convert to table format
        data = project_info.flat_map do |key, value|
          if value.is_a?(Hash)
            value.map { |k, v| [key.to_s, k.to_s, v.to_s] }
          else
            [[key.to_s, '', value.to_s]]
          end
        end
        @console.table('Project Analysis', data, headers: ['Category', 'Property', 'Value'])
      else
        project_panel = @panels.project_info(project_info)
        @console.rich_console.print(project_panel)
      end
    end

    def handle_slash_command(command, args)
      case command
      when 'save'
        filename = args.empty? ? nil : args
        filepath = @engine.conversation.save_conversation(filename)
        @console.success("Conversation saved to #{filepath}")
      when 'load'
        if args.empty?
          @console.error("Please provide a conversation filename")
        else
          if @engine.conversation.load_conversation(args)
            @console.success("Conversation loaded from #{args}")
          else
            @console.error("Failed to load conversation: #{args}")
          end
        end
      when 'clear'
        @engine.conversation.clear!
        @console.success("Conversation cleared")
      when 'stats'
        stats = @engine.conversation.stats
        stats_panel = @panels.conversation_summary(stats)
        @console.rich_console.print(stats_panel)
      else
        @console.warning("Unknown command: /#{command}")
        show_slash_commands_help
      end
    end

    def show_chat_help
      @console.header('Chat Commands', level: 2)
      
      commands = {
        'Basic Commands' => [
          { name: 'help', description: 'Show this help message' },
          { name: 'status', description: 'Show system status' },
          { name: 'clear', description: 'Clear the terminal' },
          { name: 'exit/quit', description: 'Exit chat mode' }
        ],
        'Slash Commands' => [
          { name: '/save [filename]', description: 'Save current conversation' },
          { name: '/load <filename>', description: 'Load a conversation' },
          { name: '/clear', description: 'Clear conversation history' },
          { name: '/stats', description: 'Show conversation statistics' }
        ]
      }

      help_panel = @panels.help(commands)
      @console.rich_console.print(help_panel)
    end

    def show_comprehensive_help
      commands = {
        'Core Commands' => [
          { name: 'chat [MESSAGE]', description: 'Start interactive chat or send single message' },
          { name: 'ask MESSAGE', description: 'Ask a single question' },
          { name: 'generate TYPE [DESC]', description: 'Generate code or content' },
          { name: 'analyze [PATH]', description: 'Analyze project or file' }
        ],
        'Management' => [
          { name: 'init', description: 'Initialize configuration' },
          { name: 'config', description: 'Manage configuration' },
          { name: 'conversation', description: 'Manage conversations' },
          { name: 'status', description: 'Show system status' },
          { name: 'dashboard', description: 'Show comprehensive dashboard' }
        ],
        'Information' => [
          { name: 'version', description: 'Show version information' },
          { name: 'help [COMMAND]', description: 'Show help for specific command' }
        ]
      }

      help_panel = @panels.help(commands)
      @console.rich_console.print(help_panel)
    end

    # Subcommand classes would be defined here or in separate files
    # class ConfigCommands < Thor
    #   # Configuration management commands
    # end

    # class ConversationCommands < Thor  
    #   # Conversation management commands
    # end
  end
end