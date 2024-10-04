require 'json'
require_relative './config'
require_relative './openai'

# ==================================================
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
    @history_file = HistoryFile
    @history = {}
    read_history_file()
  end


  def clear()
    @oai.clear()
    puts "CLEAR!!!"
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

    if @history.has_key?(user_id)
      @history[user_id].push(buffer.join("\n"))
      if @history[user_id].size > 3
        @history[user_id].shift
        puts "cut!!"
        puts @history[user_id].size
      end
    else
      @history[user_id] = [buffer.join("\n")]
    end

    return buffer.join("\n")
  end


  def load_history(user_id)
    if @history.has_key?(user_id)
      return @history[user_id].join("\n")
    else
      return "(履歴はありません)<br>"
    end
  end


  def close()
    puts "closing..."
    store_history()
    puts "done"
  end


  private

  def store_history()
    File.open(@history_file, "w"){|fp|
      fp.write(JSON.generate(@history))
    }

    # format of history
    # hash
    # key: user_id
    # value: list of string


  end

  def read_history_file()
    if FileTest.exist?(@history_file)
      File.open(@history_file){|fp|
        @history = JSON.parse(fp.read())
      }
    end
  end

  def store_to_corpus(timestamp, user_id, query, response)
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

