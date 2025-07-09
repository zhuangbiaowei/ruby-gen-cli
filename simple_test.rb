#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

# 简单的API测试
def test_siliconflow_api
  uri = URI('https://api.siliconflow.cn/v1/chat/completions')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request['Authorization'] = "Bearer #{ENV['SILICONFLOW_API_KEY']}"
  
  request.body = JSON.generate({
    model: 'deepseek-ai/DeepSeek-V2.5',
    messages: [
      { role: 'user', content: 'What is Ruby programming language? Please answer in one sentence.' }
    ],
    max_tokens: 100
  })
  
  response = http.request(request)
  
  if response.code == '200'
    result = JSON.parse(response.body)
    puts "✅ API Test Successful!"
    puts "Response: #{result['choices'][0]['message']['content']}"
    return true
  else
    puts "❌ API Test Failed!"
    puts "Status: #{response.code}"
    puts "Body: #{response.body}"
    return false
  end
rescue => e
  puts "❌ API Test Error: #{e.message}"
  return false
end

if __FILE__ == $0
  puts "Testing SiliconFlow API directly..."
  test_siliconflow_api
end