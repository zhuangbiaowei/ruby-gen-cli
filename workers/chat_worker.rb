# frozen_string_literal: true

# Chat worker for Ruby Gen CLI
# Handles conversational interactions with context awareness

SmartPrompt.define_worker :chat do
  # Use the default LLM from configuration
  use config.default_llm || 'SiliconFlow'
  
  # Set temperature for conversational responses
  temperature params[:temperature] || 0.7
  
  # System message with context awareness
  sys_msg(
    template(:system_prompt, {
      context: params[:context],
      project_info: params[:project_info],
      conversation_history: params[:conversation_history]
    })
  )
  
  # Main user message with conversation context
  if params[:with_history] && params[:conversation_history]
    # Include conversation history for context
    params[:conversation_history].each do |msg|
      message(msg[:role], msg[:content])
    end
  end
  
  # Current user message
  message('user', params[:message])
  
  # Send the message and get response
  send_msg
end