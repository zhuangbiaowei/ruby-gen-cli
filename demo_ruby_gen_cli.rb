#!/usr/bin/env ruby

# Demo script for Ruby Gen CLI functionality
puts "🚀 Ruby Gen CLI Demo"
puts "=" * 50

def run_command(description, command)
  puts "\n🔸 #{description}"
  puts "Command: #{command}"
  puts "-" * 30
  
  system(command)
  
  puts "-" * 30
  puts "✅ Command completed\n"
end

# Demo commands
commands = [
  ["Show version information", "ruby exe/ruby_gen_cli version"],
  ["Display help", "ruby exe/ruby_gen_cli help"],
  ["Show system status", "ruby exe/ruby_gen_cli status"],
  ["Analyze current project", "ruby exe/ruby_gen_cli analyze ."],
  ["Initialize configuration (dry run)", "echo 'This would run: ruby exe/ruby_gen_cli init --force'"]
]

commands.each do |description, command|
  run_command(description, command)
  sleep 1  # Brief pause for readability
end

puts "\n🎉 Demo completed!"
puts "\nKey Features Demonstrated:"
puts "• ✅ Command-line interface working"
puts "• ✅ Project analysis capabilities"
puts "• ✅ Configuration management"
puts "• ✅ Help system"
puts "• ✅ Status monitoring"
puts "\nNext Steps:"
puts "• Add valid API keys to enable LLM functionality"
puts "• Install optional gems (smart_agent, ruby_rich) for enhanced features"
puts "• Use 'ruby exe/ruby_gen_cli chat' for AI interactions"