require 'net/https'
require 'json'

class OpenAI
  def initialize(uri, key, model, temp, max_tokens, role, enable_cache = false)
    @cache_file = "./cache_openai"
    @response_cache = {}

    uri = URI.parse(uri)
    @ns = Net::HTTP.new(uri.host, uri.port)
    @ns.use_ssl = true
    @ns.verify_mode = OpenSSL::SSL::VERIFY_NONE

    @request = Net::HTTP::Post.new(uri.path)

    # header
    @request['Content-Type'] = 'application/json'
    @request['Authorization'] = key

    @enable_cache = enable_cache
    if @enable_cache == true
      read_cache_from_log()
    end

    @model = model
    @temp = temp
    @max_tokens = max_tokens
    @role = role
    @messages = []


    self.clear()
  end


  def clear()
    @messages = []
    @messages.push({
                     "role" => "system",
                     "content" => @role
                   })
  end


  def get_answer(content)

    if @enable_cache == true && @response_cache.has_key?(content)
      puts "Cache used"
      return @response_cache[content]
    end

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
      "request" => params,
      "response" => data
    }
    put_log(JSON.generate(log_data))

    system_utterance = data["choices"][0]["message"]["content"]

    @messages.push({
                     "role" => "assistant",
                     "content" => system_utterance
                   })

    if @enable_cache
      @response_cache[content] = system_utterance
    end

    return system_utterance
  end


  def close()
  end


  private

  def put_log(content)
    File.open(@cache_file, "a"){|fp|
      fp.puts content
    }
  end


  def read_cache_from_log()
    if FileTest.exist?(@cache_file)

      File.open(@cache_file){|fp|
        fp.each_line{|line|
          data = JSON.parse(line.chomp)
          user_utt = nil
          # puts data["request"]["messages"]
          data["request"]["messages"].each{|msg|
            if msg["role"] == "user"
              user_utt = msg["content"]
            end
          }
          system_utt = data["response"]["choices"][0]["message"]["content"]
          puts "-----------"
          puts user_utt
          puts "---"
          puts system_utt
          @response_cache[user_utt] = system_utt
        }
      }
      

    end

  end



end
