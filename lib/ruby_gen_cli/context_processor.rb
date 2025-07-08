# frozen_string_literal: true

require 'fileutils'
require 'pathname'

module RubyGenCli
  # Processes and manages project context for AI interactions
  class ContextProcessor
    attr_reader :config_manager, :current_directory, :project_info

    def initialize(config_manager)
      @config_manager = config_manager
      @current_directory = Dir.pwd
      @project_info = analyze_project
    end

    # Analyze current project/directory
    def analyze_project
      info = {
        path: @current_directory,
        name: File.basename(@current_directory),
        type: detect_project_type,
        files: {},
        git_info: git_information,
        size_stats: directory_stats
      }
      
      info[:files] = scan_important_files
      info
    end

    # Get project context for AI
    def get_context(include_files: true, max_file_size: 10_000)
      context = {
        project: @project_info.slice(:name, :type, :git_info),
        working_directory: @current_directory,
        timestamp: Time.now.iso8601
      }
      
      if include_files
        context[:important_files] = get_important_files_content(max_file_size)
        context[:file_tree] = get_file_tree
      end
      
      context
    end

    # Get file tree structure
    def get_file_tree(max_depth: 3, ignore_patterns: nil)
      ignore_patterns ||= default_ignore_patterns
      build_file_tree(@current_directory, max_depth, ignore_patterns)
    end

    # Get content of important files
    def get_important_files_content(max_size = 10_000)
      important_files = @project_info[:files][:important] || []
      content = {}
      
      important_files.each do |file_path|
        full_path = File.join(@current_directory, file_path)
        next unless File.exist?(full_path) && File.file?(full_path)
        next if File.size(full_path) > max_size

        begin
          content[file_path] = File.read(full_path)
        rescue StandardError => e
          content[file_path] = "Error reading file: #{e.message}"
        end
      end
      
      content
    end

    # Search for files matching pattern
    def search_files(pattern, in_content: false)
      results = []
      
      Dir.glob(File.join(@current_directory, '**', '*'), File::FNM_DOTMATCH).each do |file|
        next unless File.file?(file)
        next if should_ignore_file?(file)
        
        relative_path = Pathname.new(file).relative_path_from(Pathname.new(@current_directory)).to_s
        
        if in_content
          # Search in file content
          begin
            content = File.read(file)
            if content.match?(pattern)
              results << {
                path: relative_path,
                matches: content.scan(pattern).flatten
              }
            end
          rescue StandardError
            # Skip files that can't be read
          end
        else
          # Search in filename
          results << { path: relative_path } if relative_path.match?(pattern)
        end
      end
      
      results
    end

    # Get recent Git changes
    def get_recent_changes(days: 7)
      return {} unless git_repository?

      begin
        since_date = (Date.today - days).strftime('%Y-%m-%d')
        log_output = `git log --since="#{since_date}" --pretty=format:"%h|%an|%ad|%s" --date=short 2>/dev/null`
        
        commits = log_output.split("\n").map do |line|
          hash, author, date, message = line.split('|', 4)
          {
            hash: hash,
            author: author,
            date: date,
            message: message
          }
        end
        
        {
          commits: commits,
          total_commits: commits.length,
          period: "#{days} days"
        }
      rescue StandardError
        {}
      end
    end

    # Refresh project analysis
    def refresh!
      @current_directory = Dir.pwd
      @project_info = analyze_project
    end

    # Get summary for AI context
    def get_summary
      summary = "Project: #{@project_info[:name]} (#{@project_info[:type]})\n"
      summary += "Location: #{@current_directory}\n"
      
      if @project_info[:git_info][:is_repo]
        summary += "Git: #{@project_info[:git_info][:branch]} branch"
        summary += " (#{@project_info[:git_info][:status]})\n"
      end
      
      summary += "Files: #{@project_info[:size_stats][:total_files]} total"
      summary += " (#{format_file_size(@project_info[:size_stats][:total_size])})\n"
      
      if @project_info[:files][:important]&.any?
        summary += "Key files: #{@project_info[:files][:important].join(', ')}"
      end
      
      summary
    end

    private

    def detect_project_type
      # Check for specific project markers
      if File.exist?(File.join(@current_directory, 'Gemfile'))
        'Ruby'
      elsif File.exist?(File.join(@current_directory, 'package.json'))
        'Node.js'
      elsif File.exist?(File.join(@current_directory, 'requirements.txt')) || 
            File.exist?(File.join(@current_directory, 'pyproject.toml'))
        'Python'
      elsif File.exist?(File.join(@current_directory, 'pom.xml'))
        'Java (Maven)'
      elsif File.exist?(File.join(@current_directory, 'Cargo.toml'))
        'Rust'
      elsif File.exist?(File.join(@current_directory, 'go.mod'))
        'Go'
      elsif Dir.exist?(File.join(@current_directory, '.git'))
        'Git Repository'
      else
        'General'
      end
    end

    def git_information
      return { is_repo: false } unless git_repository?

      begin
        branch = `git branch --show-current 2>/dev/null`.strip
        status_output = `git status --porcelain 2>/dev/null`
        remote_url = `git config --get remote.origin.url 2>/dev/null`.strip
        
        {
          is_repo: true,
          branch: branch.empty? ? 'unknown' : branch,
          status: status_output.empty? ? 'clean' : 'modified',
          remote_url: remote_url.empty? ? nil : remote_url,
          has_uncommitted: !status_output.empty?
        }
      rescue StandardError
        { is_repo: true, error: 'Unable to read git information' }
      end
    end

    def git_repository?
      Dir.exist?(File.join(@current_directory, '.git'))
    end

    def directory_stats
      total_files = 0
      total_size = 0
      
      Dir.glob(File.join(@current_directory, '**', '*')).each do |file|
        next unless File.file?(file)
        next if should_ignore_file?(file)
        
        total_files += 1
        total_size += File.size(file)
      end
      
      {
        total_files: total_files,
        total_size: total_size
      }
    end

    def scan_important_files
      important_files = []
      config_files = []
      source_files = []
      
      # Common important files
      %w[
        README.md README.txt README
        package.json Gemfile requirements.txt
        Dockerfile docker-compose.yml
        .gitignore .env.example
        LICENSE LICENSE.txt
        CHANGELOG.md CHANGELOG.txt
      ].each do |file|
        important_files << file if File.exist?(File.join(@current_directory, file))
      end
      
      # Find configuration files
      Dir.glob(File.join(@current_directory, '*')).each do |file|
        next unless File.file?(file)
        
        basename = File.basename(file)
        if basename.match?(/\.(ya?ml|json|toml|ini|conf|config)$/i)
          config_files << basename
        elsif basename.match?(/\.(rb|js|py|java|go|rs|ts)$/i)
          source_files << basename
        end
      end
      
      {
        important: important_files,
        config: config_files.first(5), # Limit to avoid too many files
        source: source_files.first(10)
      }
    end

    def build_file_tree(directory, max_depth, ignore_patterns, current_depth = 0)
      return {} if current_depth >= max_depth
      
      tree = {}
      
      Dir.entries(directory).sort.each do |entry|
        next if entry.start_with?('.')
        
        full_path = File.join(directory, entry)
        next if should_ignore_path?(full_path, ignore_patterns)
        
        if File.directory?(full_path)
          tree[entry + '/'] = build_file_tree(full_path, max_depth, ignore_patterns, current_depth + 1)
        else
          tree[entry] = File.size(full_path)
        end
      end
      
      tree
    end

    def should_ignore_file?(file)
      basename = File.basename(file)
      dirname = File.dirname(file)
      
      # Ignore hidden files
      return true if basename.start_with?('.')
      
      # Ignore common build/temp directories
      ignore_dirs = %w[node_modules .git dist build tmp temp .idea .vscode]
      return true if ignore_dirs.any? { |dir| dirname.include?(dir) }
      
      # Ignore binary files by extension
      ignore_extensions = %w[.exe .dll .so .dylib .class .jar .war .zip .tar.gz .tgz]
      return true if ignore_extensions.any? { |ext| basename.end_with?(ext) }
      
      false
    end

    def should_ignore_path?(path, patterns)
      patterns.any? { |pattern| File.fnmatch(pattern, path) }
    end

    def default_ignore_patterns
      %w[
        **/node_modules/**
        **/.git/**
        **/dist/**
        **/build/**
        **/tmp/**
        **/temp/**
        **/.idea/**
        **/.vscode/**
        **/*.log
        **/*.tmp
      ]
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
  end
end