require 'open3'
require 'json'

require_relative './config'

class CHATREC
  def initialize()
  end

  def run(code)
    
    sid = "SID"
    timestamp = Time.now.strftime("%Y/%m/%d %H:%M:%S")

    buffer = []
    buffer.push("Success: (#{timestamp})<br>\n")
    buffer.push("わたし、#{code}については知りません。")
    buffer.join("<br>")

    return buffer
  end

  def close()
  end

end

