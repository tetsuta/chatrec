require 'open3'
require 'json'

require_relative './config'

class CODEX
  def initialize()
    @python = Python
  end

  def run(code)
    
    sid = "SID"
    detail_timestamp = Time.now.strftime("%Y%m%dT%H%M%S")

    buff_code_file = "#{TmpCodeDir}/buffer_#{sid}_#{detail_timestamp}.py"

    filepath = File.absolute_path(buff_code_file)
    File.open(buff_code_file, "w"){|wp|
      wp.write(code)
    }

    output, error, status = Open3.capture3("#{@python} #{buff_code_file}")
    
    buffer = ""

    error.gsub!(/#{filepath}/,"code_file")

    timestamp = Time.now.strftime("%Y/%m/%d %H:%M:%S")
    if status.exitstatus == 0
      buffer << "Success: (#{timestamp})<br>\n"
      output.each_line{|line|
        buffer << line.chomp + "<br>\n"
      }
    else
      buffer << "Error: (#{timestamp})<br>\n"
      buffer << "<font color='red'>\n"
      error.each_line{|line|
        buffer << line.chomp + "<br>\n"
      }
      buffer << "</font>\n"
    end

    return buffer
  end

  def close()
  end

end

