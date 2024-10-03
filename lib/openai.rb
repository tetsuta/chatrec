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

    @log_file = "./openai_log"
  end


  def put_log(content)
    File.open(@log_file, "a"){|fp|
      fp.puts content
    }
  end


  def get_answer(content)
    # body
    params = {"model" => @model,
              "messages" => [  
                {
                  "role" => "system",
                  "content" => @role
                }, 
                {
                  "role" => "user",
                  "content" => content
                }
              ],
              "temperature" => @temp,
              "max_tokens" => @max_tokens
             }
    
    @request.body = JSON.generate(params)
    response = @ns.request(@request)
    body_str = response.body
    data = JSON.parse(body_str)

    log_data = {
      "request" => @request.body,
      "response" => data
    }
    put_log(JSON.generate(log_data))

    return data["choices"][0]["message"]["content"]
  end


  def close()
  end

end
