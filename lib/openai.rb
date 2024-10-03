require 'net/https'
require 'json'

class OpenAI
  def initialize(uri, key, model, temp, max_tokens, role)
    uri = URI.parse(uri)
    @ns = Net::HTTP.new(uri.host, uri.port)
    @ns.use_ssl = true
    @ns.verify_mode = OpenSSL::SSL::VERIFY_NONE

    @request = Net::HTTP::Post.new(uri.path)

    # header
    @request['Content-Type'] = 'application/json'
    @request['Authorization'] = key

    @model = model
    @temp = temp
    @max_tokens = max_tokens
    @role = role
    @messages = []
    @log_file = "./openai_log"

    self.clear()
  end


  def clear()
    @messages = []
    @messages.push({
                     "role" => "system",
                     "content" => @role
                   })
  end


  def put_log(content)
    File.open(@log_file, "a"){|fp|
      fp.puts content
    }
  end


  def get_answer(content)

    @messages.push({
                     "role" => "user",
                     "content" => content
                   })

    # puts "---------------"
    # puts "messages"
    # puts @messages

    params = {"model" => @model,
              "messages" => @messages,
              "temperature" => @temp,
              "max_tokens" => @max_tokens
             }
    
    @request.body = JSON.generate(params)
    response = @ns.request(@request)
    data = JSON.parse(response.body)

    log_data = {
      "request" => @request.body,
      "response" => data
    }
    put_log(JSON.generate(log_data))

    system_utterance = data["choices"][0]["message"]["content"]

    @messages.push({
                     "role" => "assistant",
                     "content" => system_utterance
                   })

    return system_utterance
  end


  def close()
  end

end
