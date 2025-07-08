# frozen_string_literal: true

require 'ruby_rich'

module RubyGenCli
  module UI
    # Enhanced console interface using RubyRich
    class Console
      attr_reader :rich_console, :config_manager

      def initialize(config_manager)
        @config_manager = config_manager
        @rich_console = RubyRich::Console.new
        configure_theme
      end

      # Print styled text
      def print(text, style: nil)
        if style
          @rich_console.print("[#{style}]#{text}[/#{style}]")
        else
          @rich_console.print(text)
        end
      end

      # Print with newline
      def puts(text, style: nil)
        print(text, style: style)
        @rich_console.print("\n")
      end

      # Print success message
      def success(message)
        puts("✅ #{message}", style: 'bold green')
      end

      # Print error message
      def error(message)
        puts("❌ #{message}", style: 'bold red')
      end

      # Print warning message  
      def warning(message)
        puts("⚠️  #{message}", style: 'bold yellow')
      end

      # Print info message
      def info(message)
        puts("ℹ️  #{message}", style: 'bold blue')
      end

      # Print debug message
      def debug(message)
        return unless @config_manager.get('log_level') == 'debug'
        puts("🐛 #{message}", style: 'dim')
      end

      # Create and display a panel
      def panel(content, title: nil, border_style: 'rounded', padding: 1)
        panel = RubyRich::Panel.new(
          content,
          title: title,
          border_style: border_style,
          padding: padding
        )
        @rich_console.print(panel)
      end

      # Create and display a table
      def table(title, data, headers: nil)
        columns = headers&.length || (data.first&.length || 3)
        rich_table = RubyRich::Table.new(title, columns: columns)
        
        # Add headers if provided
        if headers
          rich_table.add_row(*headers)
        end
        
        # Add data rows
        data.each do |row|
          rich_table.add_row(*row)
        end
        
        @rich_console.print(rich_table)
      end

      # Show loading message
      def loading(message)
        puts("⏳ #{message}", style: 'yellow')
      end

      # Clear the console
      def clear
        system('clear') || system('cls')
      end

      # Ask for user input with a prompt
      def ask(question, default: nil)
        prompt = question
        prompt += " [#{default}]" if default
        prompt += ": "
        
        print(prompt, style: 'bold cyan')
        input = STDIN.gets.chomp
        
        input.empty? && default ? default : input
      end

      # Ask for yes/no confirmation
      def confirm(question, default: false)
        default_text = default ? 'Y/n' : 'y/N'
        answer = ask("#{question} (#{default_text})", default: default ? 'y' : 'n')
        
        answer.downcase.start_with?('y')
      end

      # Display a status indicator
      def status(message, &block)
        print("#{message}... ", style: 'cyan')
        
        if block_given?
          begin
            result = yield
            success('Done')
            result
          rescue StandardError => e
            error("Failed: #{e.message}")
            raise
          end
        end
      end

      # Create a progress context
      def progress(description, total: nil, &block)
        if total
          # Use RubyRich progress bar for determinate progress
          RubyRich::ProgressBar.new(description, total: total).with_progress(&block)
        else
          # Simple spinner for indeterminate progress
          loading(description)
          yield if block_given?
        end
      end

      # Print a separator line
      def separator(char: '─', length: 80, style: 'dim')
        puts(char * length, style: style)
      end

      # Print a header
      def header(text, level: 1)
        case level
        when 1
          puts("\n" * 2 + text, style: 'bold magenta')
          separator(char: '═', style: 'magenta')
        when 2
          puts("\n" + text, style: 'bold blue')
          separator(char: '─', style: 'blue')
        else
          puts(text, style: 'bold')
        end
      end

      # Print formatted JSON
      def json(data, indent: 2)
        require 'json'
        formatted = JSON.pretty_generate(data, indent: ' ' * indent)
        panel(formatted, title: 'JSON Output', border_style: 'rounded')
      end

      # Print code with syntax highlighting (simple)
      def code(content, language: 'text', title: nil)
        panel_title = title || "Code (#{language})"
        panel(content, title: panel_title, border_style: 'double')
      end

      # Print a list of items
      def list(items, style: 'bullet', indent: 2)
        items.each_with_index do |item, index|
          prefix = case style.to_sym
                   when :bullet then '•'
                   when :number then "#{index + 1}."
                   when :arrow then '→'
                   else '•'
                   end
          
          puts("#{' ' * indent}#{prefix} #{item}")
        end
      end

      # Print key-value pairs
      def key_value(pairs, align: :left)
        max_key_length = pairs.keys.map(&:to_s).map(&:length).max
        
        pairs.each do |key, value|
          formatted_key = case align
                          when :right then key.to_s.rjust(max_key_length)
                          else key.to_s.ljust(max_key_length)
                          end
          
          puts("#{formatted_key}: #{value}", style: 'cyan')
        end
      end

      # Show help text in a formatted way
      def help(commands)
        header('Available Commands', level: 1)
        
        commands.each do |category, command_list|
          header(category, level: 2)
          
          command_data = command_list.map do |cmd|
            [cmd[:name], cmd[:description] || 'No description']
          end
          
          table(nil, command_data, headers: ['Command', 'Description'])
          puts("")
        end
      end

      # Print configuration information
      def config_info(config_data)
        header('Configuration', level: 1)
        
        config_data.each do |section, data|
          header(section.to_s.capitalize, level: 2)
          
          if data.is_a?(Hash)
            key_value(data)
          else
            puts(data.to_s)
          end
          
          puts("")
        end
      end

      private

      def configure_theme
        theme_name = @config_manager.get('ui.color_scheme', 'auto')
        
        # Configure RubyRich theme based on settings
        case theme_name.to_s
        when 'dark'
          configure_dark_theme
        when 'light'
          configure_light_theme
        else
          # Auto-detect or use default
          configure_auto_theme
        end
      end

      def configure_dark_theme
        # Set up dark theme colors
        @rich_console.theme = RubyRich::Theme.new(
          success: 'bold green',
          error: 'bold red',
          warning: 'bold yellow',
          info: 'bold cyan',
          highlight: 'bold magenta'
        )
      end

      def configure_light_theme
        # Set up light theme colors
        @rich_console.theme = RubyRich::Theme.new(
          success: 'green',
          error: 'red',
          warning: 'yellow',
          info: 'blue',
          highlight: 'magenta'
        )
      end

      def configure_auto_theme
        # Use default theme or auto-detect based on terminal
        # For now, use default theme
      end
    end
  end
end