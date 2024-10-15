require 'json'
require 'leveldb'
require_relative './config'
require_relative './openai'

# ==================================================
class CHATREC
  def initialize(user_id, history_db)

    @user_id = user_id
    @history_db = history_db
    @history = []
    read_history_db()

    uri = "https://api.openai.com/v1/chat/completions"
    key = "Bearer #{OpenAI_Key}"
    model = "gpt-4o-mini"
    temp = 0.7
    max_tokens = 1000
    role = "あなたは有能なアシスタントです。日本語で答えます。"

    @used_at = nil
    set_timestamp()

    enable_cache = false
    # enable_cache = true
    @oai = OpenAI.new(uri, key, model, temp, max_tokens, role, enable_cache, CacheFile)

    @corpus_file = CorpusFile

    type = "initialize"
    store_to_corpus(type, "", "")
  end


  def status
    buffer = []
    buffer.push("user_id: #{@user_id}")
    buffer.push("last used: #{@used_at.strftime("%Y%m%d %H:%M:%S")}")
    buffer.push("age: #{age()}")
    return buffer.join("\n")
  end


  def clear()
    set_timestamp()

    @oai.clear()
    type = "clear"
    query = ""
    response = ""
    store_to_corpus(type, query, response)
    puts "CLEAR!!!"

  end


  def run(query)
    set_timestamp()

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

    type = "dialog"
    store_to_corpus(type, query, response)


    @history.push(buffer.join("\n"))
    if @history.size > 3
      @history.shift
    end

    @history_db[@user_id] = JSON.generate(@history)


    return buffer.join("\n")
  end


  def load_history()
    set_timestamp()

    if @history.size == 0
      return "(履歴はありません)<br>"
    else
      return @history.join("\n")
    end

  end


  def age()
    now = Time.now()
    return now - @used_at
  end


  private

  def set_timestamp()
    @used_at = Time.now()
  end

  
  def read_history_db()
    val = @history_db[@user_id]
    if val != nil
      @history = JSON.parse(val)
    end
  end


  def store_to_corpus(type, query, response)
    timestamp = Time.now.strftime("%Y/%m/%d %H:%M:%S")
    data = {
      "timestamp" => timestamp,
      "user_id" => @user_id,
      "type" => type,
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

