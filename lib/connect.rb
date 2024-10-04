#!/usr/bin/ruby
# coding: utf-8

require 'json'
require 'net/http'
require 'getoptlong'

opts = GetoptLong.new(
 		      [ "--mode", "-m", GetoptLong::REQUIRED_ARGUMENT ],
		      [ "--help", "-h", GetoptLong::NO_ARGUMENT ]
		      )

def printHelp(message)
  STDERR.print message
  exit(1)
end

USAGE_MESSAGE = "
Usage:
 ./connect.rb [-h] [-m mode]

mode:
stop

"

mode = "stop"
opts.each{|opt, arg|
  case opt
  when "--help"
    printHelp(USAGE_MESSAGE)
  when "--mode"
    mode = arg
  end
}

if mode == nil
  printHelp(USAGE_MESSAGE)
end


# ==================================================
host = 'localhost'
port = 8103

http = Net::HTTP.start(host, port)
path = "/"
header = {'Content-Type' => 'application/json'}


case mode
when "stop"
  data = Hash::new()
  data["mode"] = mode
  response = http.post(path, JSON.generate(data), header)
  data = JSON.parse(response.body)
  p data

end

