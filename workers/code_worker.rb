# frozen_string_literal: true

# Code generation worker for Ruby Gen CLI
# Specialized in generating high-quality code in various languages

SmartPrompt.define_worker :code_generator do
  # Use the default LLM from configuration
  use 'SiliconFlow'
  
  # Set temperature for code generation (lower for more deterministic output)
  temperature params[:temperature] || 0.3
  
  # System message for code generation
  language = params[:language] || 'ruby'
  system_message = "You are an expert #{language} developer specializing in generating high-quality, production-ready code."
  system_message += "\n\nYour task is to generate clean, readable, and well-structured code following #{language} best practices."
  
  if params[:context]
    system_message += "\n\nProject Context: #{params[:context]}"
  end
  
  sys_msg(system_message)
  
  # User request for code generation - build prompt inline
  user_prompt = "Generate #{params[:language] || 'Ruby'} code for: #{params[:description]}"
  
  if params[:context]
    user_prompt += "\n\nProject Context:\n#{params[:context]}"
  end
  
  user_prompt += "\n\nPlease provide:\n1. Clean, well-commented code\n2. Following best practices\n3. Include error handling where appropriate\n4. Add documentation/comments explaining key parts"
  
  prompt(user_prompt)
  
  # Send the message and get response
  send_msg
end

# Code analysis worker
SmartPrompt.define_worker :code_analyzer do
  # Use the default LLM from configuration
  use 'SiliconFlow'
  
  # Set temperature for analysis (balanced for detailed insights)
  temperature params[:temperature] || 0.5
  
  # System message for code analysis
  sys_msg(
    "You are an expert code analyzer. Provide comprehensive analysis including:\n" \
    "- Code structure and architecture\n" \
    "- Potential issues and improvements\n" \
    "- Best practices and recommendations\n" \
    "- Security considerations\n" \
    "- Performance optimization opportunities\n\n" \
    "Be specific and actionable in your feedback."
  )
  
  # Code to analyze - build the prompt inline
  file_type = params[:file_type] || 'unknown'
  language = case file_type
             when '.rb' then 'Ruby'
             when '.js' then 'JavaScript'
             when '.py' then 'Python'
             when '.java' then 'Java'
             when '.go' then 'Go'
             when '.rs' then 'Rust'
             else 'Generic'
             end
  
  analysis_prompt = "Analyze the following #{language} code:\n\n```#{language.downcase}\n#{params[:content]}\n```\n\nProvide comprehensive analysis covering code quality, architecture, performance, and security."
  
  prompt(analysis_prompt)
  
  # Send the message and get response
  send_msg
end

# Worker definitions completed - helper functions removed as they're now inline