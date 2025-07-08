# frozen_string_literal: true

# Code generation worker for Ruby Gen CLI
# Specialized in generating high-quality code in various languages

SmartPrompt.define_worker :code_generator do
  # Use the default LLM from configuration
  use config.default_llm || 'SiliconFlow'
  
  # Set temperature for code generation (lower for more deterministic output)
  temperature params[:temperature] || 0.3
  
  # System message for code generation
  sys_msg(
    template(:code_generation, {
      language: params[:language] || 'ruby',
      project_context: params[:context],
      code_type: params[:type] || 'general'
    })
  )
  
  # User request for code generation
  user_prompt = build_code_prompt(params)
  message('user', user_prompt)
  
  # Send the message and get response
  send_msg
end

# Code analysis worker
SmartPrompt.define_worker :code_analyzer do
  # Use the default LLM from configuration
  use config.default_llm || 'SiliconFlow'
  
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
  
  # Code to analyze
  analysis_prompt = build_analysis_prompt(params)
  message('user', analysis_prompt)
  
  # Send the message and get response
  send_msg
end

# Helper method to build code generation prompt
def build_code_prompt(params)
  prompt_parts = []
  
  prompt_parts << "Generate #{params[:language] || 'Ruby'} code for: #{params[:description]}"
  
  if params[:type]
    prompt_parts << "Type: #{params[:type]}"
  end
  
  if params[:context]
    prompt_parts << "\nProject Context:"
    prompt_parts << params[:context].to_s
  end
  
  if params[:requirements]
    prompt_parts << "\nSpecific Requirements:"
    Array(params[:requirements]).each { |req| prompt_parts << "- #{req}" }
  end
  
  if params[:style_preferences]
    prompt_parts << "\nStyle Preferences:"
    prompt_parts << params[:style_preferences]
  end
  
  prompt_parts << "\nPlease provide:"
  prompt_parts << "1. Clean, well-commented code"
  prompt_parts << "2. Following best practices for #{params[:language] || 'Ruby'}"
  prompt_parts << "3. Include error handling where appropriate"
  prompt_parts << "4. Add documentation/comments explaining key parts"
  
  prompt_parts.join("\n")
end

# Helper method to build code analysis prompt
def build_analysis_prompt(params)
  prompt_parts = []
  
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
  
  prompt_parts << "Analyze the following #{language} code:"
  prompt_parts << "\n```#{language.downcase}"
  prompt_parts << params[:content]
  prompt_parts << "```"
  
  if params[:analysis_type] == 'security'
    prompt_parts << "\nFocus on security aspects including:"
    prompt_parts << "- Potential vulnerabilities"
    prompt_parts << "- Input validation issues"
    prompt_parts << "- Authentication/authorization concerns"
    prompt_parts << "- Data exposure risks"
  elsif params[:analysis_type] == 'performance'
    prompt_parts << "\nFocus on performance aspects including:"
    prompt_parts << "- Algorithmic complexity"
    prompt_parts << "- Memory usage"
    prompt_parts << "- Database query optimization"
    prompt_parts << "- Caching opportunities"
  else
    prompt_parts << "\nProvide comprehensive analysis covering:"
    prompt_parts << "- Code quality and maintainability"
    prompt_parts << "- Architecture and design patterns"
    prompt_parts << "- Performance considerations"
    prompt_parts << "- Security implications"
    prompt_parts << "- Testing coverage suggestions"
    prompt_parts << "- Refactoring opportunities"
  end
  
  prompt_parts.join("\n")
end