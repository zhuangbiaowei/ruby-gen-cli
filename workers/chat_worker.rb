# frozen_string_literal: true

# Chat worker for Ruby Gen CLI
# Handles conversational interactions with context awareness

SmartPrompt.define_worker :chat do
  # Use the default LLM from configuration
  use 'siliconflow'
  
  # Set temperature for conversational responses
  temperature params[:temperature] || 0.7
  
  # System message with context awareness
  system_message = "You are Ruby Gen CLI, an intelligent development assistant built with Ruby."
  
  if params[:context]
    system_message += "\n\nCurrent context: #{params[:context]}"
  end
  
  system_message += "\n\nPlease provide helpful, accurate, and actionable responses."
  
  sys_msg(system_message)
  
  # Main user message (history handling would be done differently in SmartPrompt)
  prompt(params[:message])
  
  # Send the message and get response
  send_msg
end