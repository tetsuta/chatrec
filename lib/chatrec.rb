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
    role = "あなたは有能なアシスタントです。日本語で答えます。"

    # enable_cache = false
    enable_cache = true
    @oai = OpenAI.new(uri, key, model, temp, max_tokens, role, enable_cache, CacheFile)

    @corpus_file = CorpusFile
  end


  def run(query, user_id)
    sid = "SID"
    timestamp = Time.now.strftime("%Y/%m/%d %H:%M:%S")
    response = @oai.get_answer(query)

    buffer = []
    buffer.push("<div class=\"user_block\">")
    buffer.push("<div class=\"user_utt\">")
    buffer.push(query)
    buffer.push("</div>")
    buffer.push("</div>")
    buffer.push("")
    buffer.push("<div class=\"system_utt\">")
    buffer.push(format_html(response))
    buffer.push("</div>")
    buffer.push("")

    store_to_corpus(timestamp, user_id, query, response)

    return buffer.join("\n")
  end

  def close()
  end


  private

  def store_to_corpus(timestamp, user_id, query, response)
    # puts "---------------"
    # puts timestamp
    # puts user_id
    # puts query
    # puts response

    data = {
      "timestamp" => timestamp,
      "user_id" => user_id,
      "user_uttr" => query,
      "system_uttr" => response
    }
    data_str = JSON.generate(data)
    date = Time.now.strftime("%Y%m%d")
    File.open("#{@corpus_file}_#{date}", "a"){|fp|
      fp.puts data_str
    }
  end


  def format_html(text)
    output = []
    text.each_line{|line|
      line.chomp!

      if line =~ /^### /
        line.gsub!(/^### (.+)$/){|match| "<h5>#{$1}</h5>"}
        output.push(line)
      else
        line.gsub!(/\*\*([^\*]+)\*\*/){|match| "<b>#{$1}</b>"}
        output.push(line + "<br>")
      end
    }

    # puts "------------------------------ format"
    # puts text
    # puts "------------------------------"
    # puts output.join("\n")
    return output.join("\n")
  end



end

