#!/usr/bin/env ruby

# Test basic initialization without LLM calls
require_relative 'lib/ruby_gen_cli'

def test_basic_initialization
  puts "🧪 Testing Ruby Gen CLI basic initialization..."
  
  begin
    # Test config manager
    config = RubyGenCli::ConfigManager.new
    puts "✅ ConfigManager initialized successfully"
    
    # Test default LLM availability
    default_llm = config.default_llm
    puts "✅ Default LLM: #{default_llm}"
    
    # Test available LLMs
    llms = config.available_llms
    puts "✅ Available LLMs: #{llms.join(', ')}"
    
    # Test engine initialization (but don't make LLM calls)
    engine = RubyGenCli::Engine.new
    puts "✅ Engine initialized successfully"
    
    # Test health check (will show issues but shouldn't crash)
    health = engine.health_check
    puts "✅ Health check completed"
    puts "   Healthy: #{health[:healthy]}"
    if health[:issues].any?
      puts "   Issues found:"
      health[:issues].each { |issue| puts "   - #{issue}" }
    end
    
    puts "\n🎉 Basic initialization test passed!"
    return true
    
  rescue => e
    puts "❌ Basic initialization test failed: #{e.message}"
    puts "   Backtrace: #{e.backtrace.first(3).join(', ')}"
    return false
  end
end

def test_file_structure
  puts "\n🧪 Testing file structure and templates..."
  
  required_files = [
    'lib/ruby_gen_cli.rb',
    'lib/ruby_gen_cli/engine.rb', 
    'lib/ruby_gen_cli/config_manager.rb',
    'lib/ruby_gen_cli/cli.rb',
    'templates/system_prompt.erb',
    'workers/chat_worker.rb'
  ]
  
  required_files.each do |file|
    if File.exist?(file)
      puts "✅ #{file} exists"
    else
      puts "❌ #{file} missing"
    end
  end
  
  puts "\n🎉 File structure test completed!"
end

if __FILE__ == $0
  puts "=== Ruby Gen CLI Test Suite ==="
  
  success = test_basic_initialization
  test_file_structure
  
  if success
    puts "\n🎊 All basic tests passed! The core system is working."
    puts "Note: LLM connectivity issues are expected without valid API keys."
  else
    puts "\n💥 Some tests failed. Please check the configuration."
  end
end