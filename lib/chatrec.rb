require 'json'
require_relative './config'
require_relative './openai'

class CHATREC
  def initialize()

    uri = "https://api.openai.com/v1/chat/completions"
    key = "Bearer #{OpenAI_Key}"
    model = "gpt-4o-mini"
    temp = 0.7
    max_tokens = 1000
    role = ""
    @oai = OpenAI.new(uri, key, model, temp, max_tokens, role)
  end

  def run(query)
    
    sid = "SID"
    timestamp = Time.now.strftime("%Y/%m/%d %H:%M:%S")
    response = @oai.get_answer(query)

    buffer = []
    # buffer.push("Success: (#{timestamp})<br>\n")

    buffer.push("<div class=\"user_block\">")
    buffer.push("<div class=\"user_utt\">")
    buffer.push(query)
    buffer.push("</div>")
    buffer.push("</div>")
    buffer.push("")

    buffer.push("<div class=\"system_utt\">")
    buffer.push(response)
    buffer.push("</div>")
    buffer.push("")

    
    return buffer.join("\n")
  end

  def close()
  end

end

