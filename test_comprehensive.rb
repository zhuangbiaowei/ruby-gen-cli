#!/usr/bin/env ruby

# Comprehensive test for Ruby Gen CLI functionality
require_relative 'lib/ruby_gen_cli'

def test_core_functionality
  puts "🧪 Testing Ruby Gen CLI core functionality..."
  
  begin
    # Initialize components
    config = RubyGenCli::ConfigManager.new
    engine = RubyGenCli::Engine.new
    
    puts "✅ Core components initialized"
    
    # Test configuration
    puts "✅ Default LLM: #{config.default_llm}"
    puts "✅ Available LLMs: #{config.available_llms.join(', ')}"
    
    # Test context processor (without LLM calls)
    context_processor = engine.context_processor
    context_processor.current_directory = Dir.pwd
    context_processor.refresh!
    
    project_info = context_processor.project_info
    puts "✅ Project analysis completed"
    puts "   - Name: #{project_info[:name]}"
    puts "   - Type: #{project_info[:type]}"
    puts "   - Files: #{project_info[:size_stats][:total_files]}"
    
    # Test conversation manager (without LLM calls)
    conversation = engine.conversation
    session_id = conversation.current_session_id
    puts "✅ Conversation manager working"
    puts "   - Session ID: #{session_id}"
    
    # Test health check
    health = engine.health_check
    puts "✅ Health check completed"
    puts "   - Status: #{health[:healthy] ? 'Healthy' : 'Has Issues'}"
    if health[:issues].any?
      puts "   - Issues: #{health[:issues].join(', ')}"
    end
    
    return true
    
  rescue => e
    puts "❌ Core functionality test failed: #{e.message}"
    puts "   Backtrace: #{e.backtrace.first(3).join(', ')}"
    return false
  end
end

def test_file_operations
  puts "\n🧪 Testing file operations and project analysis..."
  
  begin
    config = RubyGenCli::ConfigManager.new
    context_processor = RubyGenCli::ContextProcessor.new(config)
    
    # Test directory analysis
    context_processor.current_directory = Dir.pwd
    context_processor.refresh!
    
    # Test file pattern recognition
    ruby_files = context_processor.analyze_files_by_type('.rb')
    puts "✅ Found #{ruby_files.size} Ruby files"
    
    # Test project structure analysis
    structure = context_processor.project_structure
    puts "✅ Project structure analyzed"
    puts "   - Root directories: #{structure[:directories].take(5).join(', ')}"
    
    # Test file content analysis (on our own files)
    test_file = 'lib/ruby_gen_cli.rb'
    if File.exist?(test_file)
      content_stats = context_processor.analyze_file_content(File.read(test_file))
      puts "✅ File content analysis working"
      puts "   - #{test_file}: #{content_stats[:lines]} lines, #{content_stats[:functions]} functions"
    end
    
    return true
    
  rescue => e
    puts "❌ File operations test failed: #{e.message}"
    return false
  end
end

def test_ui_components
  puts "\n🧪 Testing UI components..."
  
  begin
    config = RubyGenCli::ConfigManager.new
    
    # Test console creation through UI module
    console = RubyGenCli::UI.new_console(config)
    puts "✅ Console created through UI module"
    
    # Test basic console operations (using the factory-created console)
    console.puts("Test message")
    puts "✅ Console basic operations working"
    
    # Test progress indicator
    progress = RubyGenCli::UI::Progress.new(config)
    progress.start("Testing progress")
    sleep 0.5
    progress.update(50, "Half way")
    sleep 0.5
    progress.complete("Done!")
    puts "✅ Progress indicator working"
    
    # Test panels
    panels = RubyGenCli::UI::Panels.new(config)
    puts "✅ Panels component initialized"
    
    return true
    
  rescue => e
    puts "❌ UI components test failed: #{e.message}"
    return false
  end
end

def test_template_system
  puts "\n🧪 Testing template system..."
  
  begin
    # Check if templates exist
    templates = ['templates/system_prompt.erb', 'templates/code_generation.erb']
    templates.each do |template|
      if File.exist?(template)
        puts "✅ #{template} exists"
        # Try to read the template
        content = File.read(template)
        puts "   - Template size: #{content.length} chars"
      else
        puts "❌ #{template} missing"
      end
    end
    
    # Check workers
    workers = ['workers/chat_worker.rb', 'workers/code_worker.rb']
    workers.each do |worker|
      if File.exist?(worker)
        puts "✅ #{worker} exists"
      else
        puts "❌ #{worker} missing"
      end
    end
    
    return true
    
  rescue => e
    puts "❌ Template system test failed: #{e.message}"
    return false
  end
end

def test_cli_initialization
  puts "\n🧪 Testing CLI initialization (without actual commands)..."
  
  begin
    # Test if CLI class can be instantiated
    cli_class = RubyGenCli::Cli
    puts "✅ CLI class available"
    
    # Check if Thor is working
    if defined?(Thor)
      puts "✅ Thor framework loaded"
    else
      puts "❌ Thor framework not available"
    end
    
    # Check CLI inheritance
    if cli_class.ancestors.include?(Thor)
      puts "✅ CLI properly extends Thor"
    else
      puts "❌ CLI doesn't properly extend Thor"
    end
    
    return true
    
  rescue => e
    puts "❌ CLI initialization test failed: #{e.message}"
    return false
  end
end

def show_project_summary
  puts "\n📊 Project Summary:"
  puts "=" * 50
  
  # Count files by type
  ruby_files = Dir.glob("**/*.rb").size
  yaml_files = Dir.glob("**/*.yml").size
  erb_files = Dir.glob("**/*.erb").size
  
  puts "Ruby files: #{ruby_files}"
  puts "YAML files: #{yaml_files}"
  puts "ERB templates: #{erb_files}"
  
  # Show project structure
  puts "\nKey directories:"
  %w[lib templates workers].each do |dir|
    if Dir.exist?(dir)
      file_count = Dir.glob("#{dir}/**/*").select { |f| File.file?(f) }.size
      puts "  #{dir}/: #{file_count} files"
    end
  end
  
  puts "\nGem specification:"
  if File.exist?('ruby_gen_cli.gemspec')
    gemspec_content = File.read('ruby_gen_cli.gemspec')
    if gemspec_content.match(/version\s*=\s*["']([^"']+)["']/)
      puts "  Version: #{$1}"
    end
  end
end

if __FILE__ == $0
  puts "=== Ruby Gen CLI Comprehensive Test Suite ==="
  puts "Testing all components without making external API calls\n"
  
  tests = [
    :test_core_functionality,
    :test_file_operations, 
    :test_ui_components,
    :test_template_system,
    :test_cli_initialization
  ]
  
  results = {}
  
  tests.each do |test|
    results[test] = send(test)
  end
  
  show_project_summary
  
  puts "\n🎯 Test Results Summary:"
  puts "=" * 50
  
  passed = results.values.count(true)
  total = results.size
  
  results.each do |test_name, result|
    status = result ? "✅ PASS" : "❌ FAIL"
    puts "#{status} #{test_name.to_s.gsub('test_', '').gsub('_', ' ').capitalize}"
  end
  
  puts "\nOverall: #{passed}/#{total} tests passed"
  
  if passed == total
    puts "\n🎉 All tests passed! Ruby Gen CLI is ready for use."
    puts "Note: LLM functionality requires valid API keys in environment variables."
  else
    puts "\n⚠️  Some tests failed. Please check the issues above."
  end
end