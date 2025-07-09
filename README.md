# Ruby Gen CLI

🚀 **Ruby Gen CLI** is an intelligent command-line development assistant powered by AI. Built with Ruby, it provides code generation, project analysis, intelligent chat interactions, and development workflow automation.

## ✨ Features

- 🤖 **AI-Powered Conversations**: Interactive chat with context awareness
- 🔧 **Code Generation**: Generate code, functions, classes, and entire files
- 📊 **Project Analysis**: Intelligent analysis of project structure and files
- 🎨 **Rich Terminal UI**: Beautiful terminal interface with progress indicators
- 🔄 **Streaming Responses**: Real-time AI responses for better user experience
- 📝 **Template System**: Customizable templates for different use cases
- 🎯 **Smart Agents**: Extensible agent system for specialized tasks
- 🗂️ **Session Management**: Persistent conversation history
- ⚙️ **Multi-LLM Support**: Works with OpenAI, DeepSeek, SiliconFlow, and local models

## 🛠️ Installation

### Prerequisites

- Ruby 3.2.0 or higher
- Git (for version control integration)

### Quick Install

```bash
git clone <your-repo>
cd ruby_gen_cli
bundle install
```

### Development Setup

```bash
# Install dependencies
bundle install

# Run tests
ruby test_comprehensive.rb

# Try the demo
ruby demo_ruby_gen_cli.rb
```

### Making it Globally Available

```bash
# Add to your PATH or create a symlink
ln -s $(pwd)/exe/ruby_gen_cli /usr/local/bin/ruby_gen_cli

# Or run directly
./exe/ruby_gen_cli --help
```

## 🚀 Quick Start

### 1. Initialize Configuration

```bash
ruby exe/ruby_gen_cli init
```

### 2. Set up API Keys (Optional but Recommended)

```bash
# For SiliconFlow
export SILICONFLOW_API_KEY="your_api_key"

# For OpenAI
export OPENAI_API_KEY="your_api_key"

# For DeepSeek
export DEEPSEEK_API_KEY="your_api_key"
```

### 3. Basic Usage

```bash
# Show version
ruby exe/ruby_gen_cli version

# Get help
ruby exe/ruby_gen_cli help

# Analyze current project
ruby exe/ruby_gen_cli analyze .

# Check system status
ruby exe/ruby_gen_cli status
```

## 📖 Usage Guide

### Core Commands

#### 💬 Interactive Chat
```bash
# Start interactive session
ruby exe/ruby_gen_cli chat

# Send single message
ruby exe/ruby_gen_cli chat "Explain Ruby modules"

# Ask specific questions
ruby exe/ruby_gen_cli ask "How do I optimize this Ruby code?"
```

#### 🏗️ Code Generation
```bash
# Generate a Ruby class
ruby exe/ruby_gen_cli generate class "User authentication system"

# Generate with output file
ruby exe/ruby_gen_cli generate function "binary search" -o search.rb

# Specify programming language
ruby exe/ruby_gen_cli generate api "REST endpoints" -l python
```

#### 📊 Project Analysis
```bash
# Analyze current directory
ruby exe/ruby_gen_cli analyze

# Analyze specific file
ruby exe/ruby_gen_cli analyze lib/my_file.rb

# Deep analysis with custom depth
ruby exe/ruby_gen_cli analyze . --depth 5

# Export analysis as JSON
ruby exe/ruby_gen_cli analyze . --format json
```

#### ⚙️ Configuration Management
```bash
# Initialize with force overwrite
ruby exe/ruby_gen_cli init --force

# Show configuration status
ruby exe/ruby_gen_cli status

# Display comprehensive dashboard
ruby exe/ruby_gen_cli dashboard
```

### Advanced Features

#### 🎯 Context-Aware Interactions
Ruby Gen CLI automatically understands your project context:
- Detects project type (Ruby, Node.js, Python, etc.)
- Analyzes file structure and dependencies
- Includes relevant files in AI context
- Maintains conversation history

#### 📝 Template System
Customize AI interactions with templates:
- System prompts in `templates/system_prompt.erb`
- Code generation templates in `templates/code_generation.erb`
- Chat templates for different scenarios

#### 🔧 Worker System
Extensible worker system for specialized tasks:
- `workers/chat_worker.rb` - Conversational interactions
- `workers/code_worker.rb` - Code generation tasks
- Custom workers for specific needs

## 🎛️ Configuration

### LLM Providers

Ruby Gen CLI supports multiple LLM providers. Configure in `~/.ruby_gen_cli/llm_config.yml`:

```yaml
adapters:
  openai: OpenAIAdapter

llms:
  siliconflow:
    adapter: openai
    url: https://api.siliconflow.cn/v1
    api_key: "${SILICONFLOW_API_KEY}"
    default_model: deepseek-ai/DeepSeek-V2.5
  
  openai:
    adapter: openai
    url: https://api.openai.com/v1
    api_key: "${OPENAI_API_KEY}"
    default_model: gpt-4
  
  ollama:
    adapter: openai
    url: http://localhost:11434
    default_model: llama3.2

default_llm: siliconflow
```

### User Preferences

Customize behavior in `~/.ruby_gen_cli/config.yml`:

```yaml
temperature: 0.7
max_tokens: 4000
streaming: true
theme: default
log_level: info
conversation_history_limit: 50

ui:
  color_scheme: auto
  progress_style: bar
  panel_style: rounded
```

## 🧪 Testing

### Run All Tests
```bash
ruby test_comprehensive.rb
```

### Test Specific Components
```bash
# Basic initialization
ruby test_initialization.rb

# Demo all features
ruby demo_ruby_gen_cli.rb
```

### Test Results
- ✅ Core functionality
- ✅ File operations and project analysis
- ✅ UI components and progress indicators
- ✅ Template system and workers  
- ✅ CLI initialization and Thor integration

## 🏗️ Architecture

### Core Components

```
lib/ruby_gen_cli/
├── engine.rb           # Core orchestration engine
├── config_manager.rb   # Configuration management
├── cli.rb             # Thor-based CLI interface
├── conversation.rb    # Chat session management
├── context_processor.rb # Project analysis and context
└── ui/               # User interface components
    ├── console.rb    # Terminal output
    ├── progress.rb   # Progress indicators
    └── panels.rb     # Information panels
```

### Extension Points

- **Workers**: Define custom AI interaction patterns
- **Templates**: Customize AI prompts and responses
- **Agents**: Create specialized AI assistants
- **Tools**: Add new functionality modules

## 🔧 Development

### Adding New Features

1. **Create a Worker**:
```ruby
# workers/my_worker.rb
SmartPrompt.define_worker :my_task do
  use config.default_llm
  sys_msg("Your specialized system prompt")
  prompt(params[:input])
  send_msg
end
```

2. **Add CLI Command**:
```ruby
# In lib/ruby_gen_cli/cli.rb
desc 'mytask INPUT', 'Perform my custom task'
def mytask(input)
  result = @engine.call_worker(:my_task, input: input)
  @console.puts(result)
end
```

3. **Create Custom Agent**:
```ruby
# agents/my_agent.rb
class MyAgent < BaseAgent
  def initialize
    super(tools: [:file_reader, :code_analyzer])
  end
  
  def process(input)
    # Your agent logic
  end
end
```

### Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📚 Examples

### Code Generation Example
```bash
$ ruby exe/ruby_gen_cli generate class "Blog post model with validation"

Generated Class:
```ruby
class BlogPost
  attr_accessor :title, :content, :author, :published_at
  
  def initialize(title:, content:, author:)
    @title = title
    @content = content
    @author = author
    @published_at = nil
  end
  
  def publish!
    @published_at = Time.now
  end
  
  def published?
    !@published_at.nil?
  end
  
  def valid?
    !title.empty? && !content.empty? && !author.empty?
  end
end
```

### Project Analysis Example
```bash
$ ruby exe/ruby_gen_cli analyze

📋 Project Information
📁 Project: ruby_gen_cli
📍 Path: /path/to/project  
🔧 Type: Ruby
🌿 Branch: main (clean)
📄 Files: 29 (237.6 KB)
```

## 🐛 Troubleshooting

### Common Issues

1. **"LLM connection failed"**
   - Check your API key configuration
   - Verify network connectivity
   - Try a different LLM provider

2. **"Configuration not found"**
   - Run `ruby exe/ruby_gen_cli init` to initialize
   - Check file permissions in `~/.ruby_gen_cli/`

3. **"Smart components not available"**
   - Install optional dependencies:
     ```bash
     gem install smart_prompt smart_agent ruby_rich
     ```

### Debug Mode
```bash
ruby exe/ruby_gen_cli --debug status
```

## 🚀 Current Status

**✅ Core System Complete**
- Basic CLI interface working
- Project analysis functional
- Configuration management
- Template and worker system
- Comprehensive test suite (5/5 tests passing)

**🚧 In Progress**
- LLM integration (smart_prompt gem)
- Smart agents (smart_agent gem)
- Rich terminal UI (ruby_rich gem)

**📋 Planned Features**
- Enhanced conversation management
- File operation tools
- Code generation and editing
- Streaming responses
- Default intelligent agents

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with [Thor](https://github.com/rails/thor) for CLI functionality
- Powered by [SmartPrompt](https://github.com/your/smart_prompt) for LLM integration
- Enhanced by [SmartAgent](https://github.com/your/smart_agent) for AI agents
- Styled with [RubyRich](https://github.com/your/ruby_rich) for terminal UI

---

**Happy Coding with Ruby Gen CLI! 🚀**

*Ready to supercharge your development workflow? The core system is working perfectly - just add your API keys to unlock the full AI-powered experience!*