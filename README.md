# Ruby Gen CLI

[![Gem Version](https://badge.fury.io/rb/ruby_gen_cli.svg)](https://badge.fury.io/rb/ruby_gen_cli)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ruby Version](https://img.shields.io/badge/Ruby-3.2%2B-red)](https://www.ruby-lang.org/)

**An intelligent Ruby CLI tool for AI-powered development workflows** 🚀

Ruby Gen CLI is a powerful command-line interface that brings AI-powered development workflows to Ruby developers. Built with [smart_prompt](https://github.com/zhuangbiaowei/smart_prompt), [smart_agent](https://github.com/zhuangbiaowei/smart_agent), and [ruby_rich](https://github.com/zhuangbiaowei/ruby_rich), it provides conversational AI interaction, code generation, project analysis, and streamlined development experiences directly from your terminal.

## ✨ Features

### 🤖 **Intelligent AI Interaction**
- **Conversational Interface**: Natural language interaction with context awareness
- **Multi-LLM Support**: OpenAI, DeepSeek, SiliconFlow, Ollama, and more
- **Streaming Responses**: Real-time AI responses with live feedback
- **Context-Aware**: Automatic project and conversation context integration

### 💻 **Code Generation & Analysis**
- **Smart Code Generation**: Generate high-quality code in multiple languages
- **Project Analysis**: Comprehensive project and file analysis
- **Code Review**: AI-powered code analysis and improvement suggestions
- **Language Support**: Ruby, JavaScript, Python, Go, Rust, and more

### 🎨 **Rich Terminal Experience**
- **Beautiful UI**: Rich terminal interface with panels, progress bars, and tables
- **Interactive Mode**: Full REPL experience with command history
- **Customizable Themes**: Dark/light themes and color customization
- **Progress Tracking**: Visual progress indicators for long-running tasks

### 🛠️ **Developer Tools**
- **Project Context**: Automatic project detection and context loading
- **File Operations**: Intelligent file and directory management
- **Git Integration**: Git repository analysis and change tracking
- **Conversation Management**: Save, load, and manage conversation history

## 📦 Installation

### Prerequisites
- Ruby 3.2.0 or higher
- Bundler gem manager

### Install from RubyGems
```bash
gem install ruby_gen_cli
```

### Install from Source
```bash
git clone https://github.com/ruby-gen-cli/ruby_gen_cli.git
cd ruby_gen_cli
bundle install
bundle exec rake install
```

## 🚀 Quick Start

### 1. Initialize Configuration
```bash
ruby_gen_cli init
```

This will create the configuration directory (`~/.ruby_gen_cli`) and set up default settings.

### 2. Set Up Your API Keys
Ruby Gen CLI supports multiple LLM providers. Set up your preferred provider:

```bash
# For SiliconFlow (default)
export SILICONFLOW_API_KEY="your_api_key"

# For DeepSeek
export DEEPSEEK_API_KEY="your_api_key"

# For OpenAI
export OPENAI_API_KEY="your_api_key"
```

### 3. Start Using Ruby Gen CLI

#### Interactive Chat Mode
```bash
ruby_gen_cli
# or
ruby_gen_cli chat
```

#### Ask a Single Question
```bash
ruby_gen_cli ask "How do I implement a binary search in Ruby?"
```

#### Generate Code
```bash
ruby_gen_cli generate class "A user authentication system"
ruby_gen_cli generate function "Calculate fibonacci sequence" --language python
```

#### Analyze Your Project
```bash
ruby_gen_cli analyze
ruby_gen_cli analyze --format json
```

## 💡 Usage Examples

### Interactive Chat
```bash
$ ruby_gen_cli

┌─ 🤖 Ruby Gen CLI ──────────────────────────────┐
│                                                │
│  Welcome to Ruby Gen CLI! 🚀                  │
│                                                │
│  An intelligent CLI tool for AI-powered       │
│  development workflows.                        │
│  Built with Ruby, SmartPrompt, SmartAgent,    │
│  and RubyRich.                                 │
│                                                │
│  Version: 0.1.0                               │
│                                                │
│  Type 'help' to get started or simply ask     │
│  me anything!                                  │
│                                                │
└────────────────────────────────────────────────┘

🤖 You: Create a Ruby class for managing user sessions

🤖 Assistant: I'll create a comprehensive Ruby class for managing user sessions...
```

### Code Generation
```bash
$ ruby_gen_cli generate class "A Redis-backed cache manager" --output cache_manager.rb

⏳ Generating class...
✅ Generated class saved to cache_manager.rb
```

### Project Analysis
```bash
$ ruby_gen_cli analyze

┌─ 📋 Project Information ──────────────────────┐
│                                               │
│  📁 Project: ruby_gen_cli                    │
│  📍 Path: /home/user/ruby_gen_cli            │
│  🔧 Type: Ruby                               │
│  🌿 Branch: main (clean)                     │
│  📄 Files: 45 (2.3 MB)                      │
│                                               │
└───────────────────────────────────────────────┘
```

### System Status
```bash
$ ruby_gen_cli status

┌─ System Status ───────────────────────────────┐
│                                               │
│  ✅ Health: Healthy                          │
│  🧠 Llm: SiliconFlow                         │
│  ⚙️  Config: ~/.ruby_gen_cli                 │
│  💬 Session: 20250115_143022_123             │
│                                               │
└───────────────────────────────────────────────┘
```

## ⚙️ Configuration

Ruby Gen CLI uses YAML configuration files stored in `~/.ruby_gen_cli/`:

### LLM Configuration (`llm_config.yml`)
```yaml
llms:
  SiliconFlow:
    adapter: openai
    url: https://api.siliconflow.cn/v1/
    api_key: ENV["SILICONFLOW_API_KEY"]
    default_model: Qwen/Qwen2.5-7B-Instruct
  
  deepseek:
    adapter: openai
    url: https://api.deepseek.com
    api_key: ENV["DEEPSEEK_API_KEY"]
    default_model: deepseek-reasoner
  
  openai:
    adapter: openai
    url: https://api.openai.com/v1/
    api_key: ENV["OPENAI_API_KEY"]
    default_model: gpt-4

default_llm: SiliconFlow
```

### User Configuration (`config.yml`)
```yaml
version: 0.1.0
default_llm: SiliconFlow
temperature: 0.7
max_tokens: 4000
streaming: true
theme: default
log_level: info
conversation_history_limit: 50
auto_save_conversations: true

ui:
  color_scheme: auto
  progress_style: bar
  panel_style: rounded

paths:
  templates: ./templates
  workers: ./workers
  agents: ./agents
  tools: ./tools
```

## 🎯 Commands

### Core Commands
| Command | Description |
|---------|-------------|
| `chat [MESSAGE]` | Start interactive chat or send single message |
| `ask MESSAGE` | Ask a single question |
| `generate TYPE [DESC]` | Generate code or content |
| `analyze [PATH]` | Analyze project or file |

### Management Commands
| Command | Description |
|---------|-------------|
| `init` | Initialize configuration |
| `config` | Manage configuration settings |
| `conversation` | Manage conversation history |
| `status` | Show system status |
| `dashboard` | Show comprehensive dashboard |

### Information Commands
| Command | Description |
|---------|-------------|
| `version` | Show version information |
| `help [COMMAND]` | Show help for specific command |

### Interactive Commands
When in interactive mode, you can use these special commands:

| Command | Description |
|---------|-------------|
| `help` | Show chat help |
| `status` | Show system status |
| `clear` | Clear terminal |
| `/save [filename]` | Save conversation |
| `/load <filename>` | Load conversation |
| `/clear` | Clear conversation history |
| `/stats` | Show conversation statistics |

## 🏗️ Architecture

Ruby Gen CLI is built with a modular architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                     Ruby Gen CLI                            │
├─────────────────────────────────────────────────────────────┤
│  Thor CLI Interface                                         │
│  ├── Interactive Mode (REPL)                               │
│  ├── Command Mode (one-shot)                               │
│  └── File Operations                                        │
├─────────────────────────────────────────────────────────────┤
│  Core Engine                                                │
│  ├── Configuration Manager                                  │
│  ├── Conversation Manager                                   │
│  └── Context Processor                                      │
├─────────────────────────────────────────────────────────────┤
│  Smart Components Integration                               │
│  ├── SmartPrompt (LLM Interaction)                         │
│  ├── SmartAgent (AI Agents & Tools)                        │
│  └── RubyRich (Terminal UI)                                │
├─────────────────────────────────────────────────────────────┤
│  Built-in Tools & Agents                                   │
│  ├── Code Generator Agent                                   │
│  ├── File Operations Tool                                   │
│  ├── Project Analyzer Tool                                  │
│  └── Chat Assistant Agent                                   │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

- **Engine**: Central orchestrator managing configuration, adapters, and workers
- **Configuration Manager**: Handles user and LLM configurations
- **Conversation Manager**: Manages chat history and context
- **Context Processor**: Analyzes project structure and provides AI context
- **UI Components**: Rich terminal interface using RubyRich

## 🛠️ Development

### Setting Up Development Environment

```bash
git clone https://github.com/ruby-gen-cli/ruby_gen_cli.git
cd ruby_gen_cli
bundle install
```

### Running Tests
```bash
bundle exec rspec
```

### Code Quality
```bash
bundle exec rubocop
```

### Building the Gem
```bash
bundle exec rake build
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with ❤️ using Ruby
- Powered by [SmartPrompt](https://github.com/zhuangbiaowei/smart_prompt) for LLM integration
- Enhanced by [SmartAgent](https://github.com/zhuangbiaowei/smart_agent) for AI agents
- Beautiful UI with [RubyRich](https://github.com/zhuangbiaowei/ruby_rich)
- CLI framework powered by [Thor](https://github.com/rails/thor)

## 📞 Support

- 📖 [Documentation](https://github.com/ruby-gen-cli/ruby_gen_cli/wiki)
- 🐛 [Issue Tracker](https://github.com/ruby-gen-cli/ruby_gen_cli/issues)
- 💬 [Discussions](https://github.com/ruby-gen-cli/ruby_gen_cli/discussions)

---

**Ruby Gen CLI** - Making AI-powered development workflows accessible to Ruby developers everywhere! 🚀