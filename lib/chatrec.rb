require 'open3'
require 'json'

require_relative './config'

class CHATREC
  def initialize()
  end

  def run(query)
    
    sid = "SID"
    timestamp = Time.now.strftime("%Y/%m/%d %H:%M:%S")

    buffer = []
    # buffer.push("Success: (#{timestamp})<br>\n")

    buffer.push("<div class=\"user_block\">")
    buffer.push("<div class=\"user_utt\">")
    buffer.push(query)
    buffer.push("</div>")
    buffer.push("</div>")
    buffer.push("")

    buffer.push("<div class=\"system_utt\">")
    buffer.push("わたし、#{query}については知りません。")
    buffer.push("</div>")
    buffer.push("")

    
    return buffer.join("\n")
  end

  def close()
  end

end

