# frozen_string_literal: true

require 'json'
require 'fileutils'

module RubyGenCli
  # Manages conversation history and context
  class Conversation
    attr_reader :config_manager, :messages, :current_session_id

    def initialize(config_manager)
      @config_manager = config_manager
      @messages = []
      @current_session_id = generate_session_id
      @conversations_dir = File.join(config_manager.config_dir, 'conversations')
      
      ensure_conversations_directory
    end

    # Add a message to the conversation
    def add_message(role, content, metadata = {})
      message = {
        role: role.to_s,
        content: content,
        timestamp: Time.now.to_f,
        session_id: @current_session_id,
        metadata: metadata
      }
      
      @messages << message
      auto_save_if_enabled
      message
    end

    # Add user message
    def add_user_message(content, metadata = {})
      add_message(:user, content, metadata)
    end

    # Add assistant message
    def add_assistant_message(content, metadata = {})
      add_message(:assistant, content, metadata)
    end

    # Add system message
    def add_system_message(content, metadata = {})
      add_message(:system, content, metadata)
    end

    # Get recent messages for context
    def get_recent_messages(limit = nil)
      limit ||= @config_manager.get('conversation_history_limit', 50)
      @messages.last(limit)
    end

    # Get messages for OpenAI format
    def get_openai_messages(limit = nil)
      get_recent_messages(limit).map do |msg|
        {
          role: msg[:role],
          content: msg[:content]
        }
      end
    end

    # Clear current conversation
    def clear!
      @messages.clear
      @current_session_id = generate_session_id
    end

    # Save conversation to file
    def save_conversation(filename = nil)
      filename ||= "conversation_#{@current_session_id}.json"
      filepath = File.join(@conversations_dir, filename)
      
      conversation_data = {
        session_id: @current_session_id,
        created_at: Time.now.to_f,
        messages: @messages,
        metadata: {
          version: RubyGenCli::VERSION,
          total_messages: @messages.length
        }
      }
      
      File.write(filepath, JSON.pretty_generate(conversation_data))
      filepath
    end

    # Load conversation from file
    def load_conversation(filename)
      filepath = File.join(@conversations_dir, filename)
      return false unless File.exist?(filepath)

      begin
        data = JSON.parse(File.read(filepath), symbolize_names: true)
        @messages = data[:messages] || []
        @current_session_id = data[:session_id] || generate_session_id
        true
      rescue JSON::ParserError => e
        raise Error, "Failed to load conversation: #{e.message}"
      end
    end

    # List available conversations
    def list_conversations
      return [] unless Dir.exist?(@conversations_dir)

      Dir.glob(File.join(@conversations_dir, 'conversation_*.json')).map do |file|
        begin
          data = JSON.parse(File.read(file), symbolize_names: true)
          {
            filename: File.basename(file),
            session_id: data[:session_id],
            created_at: Time.at(data[:created_at]),
            message_count: data[:messages]&.length || 0,
            last_message: data[:messages]&.last&.dig(:content)&.truncate(100)
          }
        rescue StandardError
          nil
        end
      end.compact.sort_by { |conv| -conv[:created_at].to_f }
    end

    # Get conversation statistics
    def stats
      {
        current_session: @current_session_id,
        total_messages: @messages.length,
        user_messages: @messages.count { |m| m[:role] == 'user' },
        assistant_messages: @messages.count { |m| m[:role] == 'assistant' },
        system_messages: @messages.count { |m| m[:role] == 'system' },
        session_duration: session_duration,
        average_message_length: average_message_length
      }
    end

    # Export conversation in different formats
    def export(format = :json)
      case format.to_sym
      when :json
        export_json
      when :markdown
        export_markdown
      when :text
        export_text
      else
        raise ArgumentError, "Unsupported export format: #{format}"
      end
    end

    # Search messages by content
    def search(query, case_sensitive: false)
      pattern = case_sensitive ? query : Regexp.new(query, Regexp::IGNORECASE)
      
      @messages.select do |message|
        message[:content].match?(pattern)
      end
    end

    # Get conversation summary
    def summary(max_length: 500)
      return "Empty conversation" if @messages.empty?

      total_chars = @messages.sum { |m| m[:content].length }
      if total_chars <= max_length
        @messages.map { |m| "#{m[:role]}: #{m[:content]}" }.join("\n")
      else
        # Truncate to fit within max_length
        result = []
        current_length = 0
        
        @messages.reverse_each do |message|
          line = "#{message[:role]}: #{message[:content]}"
          if current_length + line.length <= max_length
            result.unshift(line)
            current_length += line.length
          else
            result.unshift("... (conversation truncated)")
            break
          end
        end
        
        result.join("\n")
      end
    end

    private

    def ensure_conversations_directory
      FileUtils.mkdir_p(@conversations_dir)
    end

    def generate_session_id
      Time.now.strftime('%Y%m%d_%H%M%S_%3N')
    end

    def auto_save_if_enabled
      return unless @config_manager.get('auto_save_conversations', true)
      return if @messages.length % 10 != 0 # Save every 10 messages

      save_conversation
    rescue StandardError => e
      # Silently fail auto-save to not interrupt conversation
      puts "Warning: Failed to auto-save conversation: #{e.message}" if ENV['DEBUG']
    end

    def session_duration
      return 0 if @messages.empty?

      first_message_time = @messages.first[:timestamp]
      last_message_time = @messages.last[:timestamp]
      last_message_time - first_message_time
    end

    def average_message_length
      return 0 if @messages.empty?

      total_length = @messages.sum { |m| m[:content].length }
      total_length.to_f / @messages.length
    end

    def export_json
      {
        session_id: @current_session_id,
        messages: @messages,
        stats: stats,
        exported_at: Time.now.to_f
      }.to_json
    end

    def export_markdown
      content = "# Conversation Export\n\n"
      content += "**Session ID:** #{@current_session_id}\n"
      content += "**Exported:** #{Time.now}\n\n"
      
      @messages.each_with_index do |message, index|
        content += "## Message #{index + 1} (#{message[:role].capitalize})\n\n"
        content += "#{message[:content]}\n\n"
        content += "---\n\n"
      end
      
      content
    end

    def export_text
      content = "Conversation Export\n"
      content += "Session ID: #{@current_session_id}\n"
      content += "Exported: #{Time.now}\n"
      content += "=" * 50 + "\n\n"
      
      @messages.each_with_index do |message, index|
        content += "[#{index + 1}] #{message[:role].upcase}: #{message[:content]}\n\n"
      end
      
      content
    end
  end
end