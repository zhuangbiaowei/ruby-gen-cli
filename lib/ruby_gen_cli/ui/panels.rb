# frozen_string_literal: true

# ruby_rich availability is checked in ui.rb

module RubyGenCli
  module UI
    # Panel and layout utilities using RubyRich
    class Panels
      attr_reader :config_manager

      def initialize(config_manager)
        @config_manager = config_manager
      end

      # Create a welcome panel
      def welcome(version: nil)
        content = <<~WELCOME
          Welcome to Ruby Gen CLI! 🚀
          
          An intelligent CLI tool for AI-powered development workflows.
          Built with Ruby, SmartPrompt, SmartAgent, and RubyRich.
          
          #{version ? "Version: #{version}" : ''}
          
          Type 'help' to get started or simply ask me anything!
        WELCOME

        create_panel(
          content,
          title: '🤖 Ruby Gen CLI',
          border_style: 'double',
          padding: 2
        )
      end

      # Create a status panel
      def status(data)
        content = []
        
        data.each do |key, value|
          status_icon = case key.to_s
                       when 'health' then value ? '✅' : '❌'
                       when 'llm' then '🧠'
                       when 'config' then '⚙️'
                       when 'session' then '💬'
                       else '📊'
                       end
          
          content << "#{status_icon} #{key.to_s.capitalize}: #{value}"
        end

        create_panel(
          content.join("\n"),
          title: 'System Status',
          border_style: 'rounded'
        )
      end

      # Create a conversation summary panel
      def conversation_summary(stats)
        content = <<~SUMMARY
          📊 Conversation Statistics
          
          Session ID: #{stats[:current_session]}
          Total Messages: #{stats[:total_messages]}
          User Messages: #{stats[:user_messages]}
          Assistant Messages: #{stats[:assistant_messages]}
          Average Length: #{stats[:average_message_length]&.round(1)} characters
          Duration: #{format_duration(stats[:session_duration])}
        SUMMARY

        create_panel(
          content,
          title: '💬 Conversation Summary',
          border_style: 'rounded'
        )
      end

      # Create a project info panel
      def project_info(project_data)
        content = []
        
        content << "📁 Project: #{project_data[:name]}"
        content << "📍 Path: #{project_data[:path]}"
        content << "🔧 Type: #{project_data[:type]}"
        
        if project_data[:git_info]&.dig(:is_repo)
          git_info = project_data[:git_info]
          content << "🌿 Branch: #{git_info[:branch]} (#{git_info[:status]})"
        end
        
        if project_data[:size_stats]
          stats = project_data[:size_stats]
          content << "📄 Files: #{stats[:total_files]} (#{format_file_size(stats[:total_size])})"
        end

        create_panel(
          content.join("\n"),
          title: '📋 Project Information',
          border_style: 'rounded'
        )
      end

      # Create a help panel
      def help(commands_by_category)
        content = []
        
        commands_by_category.each do |category, commands|
          content << "\n🔸 #{category.upcase}"
          content << "─" * 30
          
          commands.each do |cmd|
            description = cmd[:description] || 'No description'
            content << "  #{cmd[:name].ljust(15)} #{description}"
          end
        end

        create_panel(
          content.join("\n"),
          title: '📖 Available Commands',
          border_style: 'double',
          padding: 2
        )
      end

      # Create a configuration panel  
      def configuration(config_data)
        content = []
        
        config_data.each do |section, data|
          content << "\n🔹 #{section.upcase}"
          content << "─" * 25
          
          if data.is_a?(Hash)
            data.each do |key, value|
              formatted_value = format_config_value(value)
              content << "  #{key}: #{formatted_value}"
            end
          else
            content << "  #{data}"
          end
        end

        create_panel(
          content.join("\n"),
          title: '⚙️ Configuration',
          border_style: 'rounded',
          padding: 1
        )
      end

      # Create an error panel
      def error(error_message, details: nil)
        content = "❌ #{error_message}"
        
        if details
          content += "\n\n📝 Details:\n#{details}"
        end

        create_panel(
          content,
          title: '🚨 Error',
          border_style: 'heavy',
          style: 'bold red'
        )
      end

      # Create a success panel
      def success(message, details: nil)
        content = "✅ #{message}"
        
        if details
          content += "\n\n📋 Details:\n#{details}"
        end

        create_panel(
          content,
          title: '🎉 Success',
          border_style: 'double',
          style: 'bold green'
        )
      end

      # Create a code display panel
      def code(code_content, language: 'text', title: nil)
        panel_title = title || "Code (#{language})"
        
        create_panel(
          code_content,
          title: "💻 #{panel_title}",
          border_style: 'ascii'
        )
      end

      # Create a file tree panel
      def file_tree(tree_data, title: 'File Tree')
        content = format_file_tree(tree_data)
        
        create_panel(
          content,
          title: "🌳 #{title}",
          border_style: 'rounded'
        )
      end

      # Create a recent changes panel
      def recent_changes(changes_data)
        return create_panel("No Git repository found", title: '📈 Recent Changes') unless changes_data[:commits]

        content = []
        content << "📅 Last #{changes_data[:period]} (#{changes_data[:total_commits]} commits)"
        content << ""
        
        changes_data[:commits].first(10).each do |commit|
          short_hash = commit[:hash][0..7]
          content << "#{short_hash} #{commit[:date]} #{commit[:author]}"
          content << "  └─ #{commit[:message]}"
          content << ""
        end

        create_panel(
          content.join("\n"),
          title: '📈 Recent Changes',
          border_style: 'rounded'
        )
      end

      # Create an LLM info panel
      def llm_info(llm_data)
        content = []
        
        content << "🧠 Current LLM: #{llm_data[:name]}"
        content << "🔗 Provider: #{llm_data[:provider]}"
        content << "🌐 Model: #{llm_data[:model]}" if llm_data[:model]
        content << "🌡️  Temperature: #{llm_data[:temperature]}" if llm_data[:temperature]
        content << "📊 Max Tokens: #{llm_data[:max_tokens]}" if llm_data[:max_tokens]
        
        if llm_data[:streaming]
          content << "⚡ Streaming: Enabled"
        end

        create_panel(
          content.join("\n"),
          title: '🤖 AI Model Information',
          border_style: 'rounded'
        )
      end

      # Create a dashboard panel with multiple sections
      def dashboard(data)
        sections = []
        
        # System status section
        if data[:status]
          sections << format_dashboard_section('System', data[:status])
        end
        
        # Project section
        if data[:project]
          sections << format_dashboard_section('Project', data[:project])
        end
        
        # Conversation section
        if data[:conversation]
          sections << format_dashboard_section('Session', data[:conversation])
        end

        create_panel(
          sections.join("\n\n"),
          title: '📊 Dashboard',
          border_style: 'double',
          padding: 2
        )
      end

      private

      def create_panel(content, title: nil, border_style: 'rounded', padding: 1, style: nil)
        if RUBY_RICH_AVAILABLE
          begin
            # Try to create panel with just content and title
            if title
              RubyRich::Panel.new(content, title: title)
            else
              RubyRich::Panel.new(content)
            end
          rescue ArgumentError => e
            # If Panel creation fails, fall back to simple text
            result = []
            result << "--- #{title} ---" if title
            result << content
            result << "--- End ---"
            result.join("\n")
          end
        else
          # Return simple text representation
          result = []
          result << "--- #{title} ---" if title
          result << content
          result << "--- End ---"
          result.join("\n")
        end
      end

      def format_duration(seconds)
        return '0s' if seconds.nil? || seconds == 0
        
        hours = seconds / 3600
        minutes = (seconds % 3600) / 60
        secs = seconds % 60
        
        if hours > 0
          "#{hours.to_i}h #{minutes.to_i}m #{secs.to_i}s"
        elsif minutes > 0
          "#{minutes.to_i}m #{secs.to_i}s"
        else
          "#{secs.round(1)}s"
        end
      end

      def format_file_size(bytes)
        units = %w[B KB MB GB]
        unit_index = 0
        size = bytes.to_f
        
        while size >= 1024 && unit_index < units.length - 1
          size /= 1024
          unit_index += 1
        end
        
        "#{size.round(1)} #{units[unit_index]}"
      end

      def format_config_value(value)
        case value
        when String
          value.length > 50 ? "#{value[0..47]}..." : value
        when Hash
          "#{value.keys.length} items"
        when Array
          "#{value.length} items"
        when true, false
          value ? 'Yes' : 'No'
        else
          value.to_s
        end
      end

      def format_file_tree(tree, prefix: '', depth: 0)
        return '' if depth > 3 # Limit depth to prevent too much output
        
        lines = []
        
        tree.each_with_index do |(name, value), index|
          is_last = index == tree.length - 1
          current_prefix = is_last ? '└── ' : '├── '
          next_prefix = is_last ? '    ' : '│   '
          
          if value.is_a?(Hash)
            # Directory
            lines << "#{prefix}#{current_prefix}#{name}"
            lines << format_file_tree(value, prefix + next_prefix, depth + 1)
          else
            # File with size
            size_str = value.is_a?(Numeric) ? " (#{format_file_size(value)})" : ''
            lines << "#{prefix}#{current_prefix}#{name}#{size_str}"
          end
        end
        
        lines.join("\n")
      end

      def format_dashboard_section(title, data)
        lines = ["🔸 #{title.upcase}"]
        
        case data
        when Hash
          data.each do |key, value|
            formatted_value = format_config_value(value)
            lines << "  #{key}: #{formatted_value}"
          end
        else
          lines << "  #{data}"
        end
        
        lines.join("\n")
      end
    end
  end
end