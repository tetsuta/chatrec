#!/usr/bin/ruby

require 'time'
require 'json'
require 'rubyXL'
require 'getoptlong'

# -------------------------------------------------- #
opts = GetoptLong.new(
 		      [ "--output", "-o", GetoptLong::REQUIRED_ARGUMENT ],
 		      [ "--begin", "-b", GetoptLong::REQUIRED_ARGUMENT ],
 		      [ "--end", "-e", GetoptLong::REQUIRED_ARGUMENT ],
		      [ "--help", "-h", GetoptLong::NO_ARGUMENT ]
		      )

def printHelp(message)
  STDERR.print message
  exit(1)
end


USAGE_MESSAGE = "
Usage:
 ./extract_log.rb [-h] [-b begin_time] [-e end_time] -o output_file
"

begin_time_str = nil
end_time_str = nil
output_file = nil
opts.each{|opt, arg|
  case opt
  when "--help"
    printHelp(USAGE_MESSAGE)
  when "--output"
    output_file = arg
  when "--begin"
    begin_time_str = arg
  when "--end"
    end_time_str = arg
  end
}

if output_file == nil
  printHelp(USAGE_MESSAGE)
end

# ==================================================
begin_time = nil
end_time = nil

begin_time = Time.parse(begin_time_str) if begin_time_str != nil
end_time = Time.parse(end_time_str) if end_time_str != nil

# puts "begin"
# puts begin_time
# puts "end"
# puts end_time

# data[org][name][time_str] => {
#   type
#   user_uttr
#   system_uttr
# }

data = {}


ARGF.each{|line|
  item = JSON.parse(line.chomp)

  if item["user_id"] =~ /^([^_]+)_(.+)$/
    org = $1
    name = $2
  end
  
  unless data.has_key?(org)
    data[org] = {}
  end

  unless data[org].has_key?(name)
    data[org][name] = {}
  end

  if name =~ /^てすと/ || name =~ /^テスト/
    puts [name, item["user_uttr"]].join("\t")
  else
    timestamp = Time.parse(item["timestamp"])
    # puts timestamp
    if (begin_time == nil || begin_time <= timestamp) && (end_time == nil || timestamp <= end_time )
      data[org][name][item["timestamp"]] = {
        "type" => item["type"],
        "user_uttr" => item["user_uttr"],
        "system_uttr" => item["system_uttr"]
      }
      # puts [org, name, item["timestamp"]].join("\t")
      # puts data[org][name][item["timestamp"]]
    end
  end 

}

# --------------------------------------------------
workbook = RubyXL::Workbook.new

data.each_key{|org|
  sheet = workbook.add_worksheet(org)

  row = 0
  sheet.add_cell(row, 0, "nickname")
  sheet.add_cell(row, 1, "timestamp")
  sheet.add_cell(row, 2, "type")
  sheet.add_cell(row, 3, "user uttr")
  sheet.add_cell(row, 4, "system uttr")

  data[org].each_key{|name|
    data[org][name].keys.sort{|a,b|
      Time.parse(a) <=> Time.parse(b)
    }.each{|time_str|
      row += 1
      sheet.add_cell(row, 0, name)
      sheet.add_cell(row, 1, time_str)
      sheet.add_cell(row, 2, data[org][name][time_str]["type"])
      sheet.add_cell(row, 3, data[org][name][time_str]["user_uttr"])
      sheet.add_cell(row, 4, data[org][name][time_str]["system_uttr"])
    }
  }

}

workbook.write(output_file)

