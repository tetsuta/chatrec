#!/usr/bin/env ruby
# coding: utf-8

require 'getoptlong'
require 'webrick'
require 'webrick/https'
require 'net/protocol'
require 'logger'
# require 'socket'

require_relative './config'
require_relative './chatrec'

# -------------------------------------------------- #
opts = GetoptLong.new([ "--help", "-h", GetoptLong::NO_ARGUMENT ] )

def printHelp(message)
  STDERR.print message
  exit(1)
end

USAGE_MESSAGE = "
Extract recent messages

Usage:
 ./server.rb [-h]

-h: show help messsage
"

bot_name = nil
opts.each{|opt, arg|
  case opt
  when "--help"
    printHelp(USAGE_MESSAGE)
  end
}


# --------------------------------------------------
# def my_address
#  udp = UDPSocket.new
#  # クラスBの先頭アドレス,echoポート 実際にはパケットは送信されない。
#  udp.connect("128.0.0.0", 7)
#  adrs = Socket.unpack_sockaddr_in(udp.getsockname)[1]
#  udp.close
#  return adrs
# end

# ip_address = my_address
# config_template = nil
# File.open(CONFIG_JS_TEMPLATE){|fp|
#   config_template = fp.read
# }
# File.open(CONFIG_JS, "w"){|fp|
#   fp.write(config_template.sub("_SERVER_HOST_ADDRESS_", ip_address))
# }

# --------------------------------------------------
$logger = Logger.new(LogFile, LogAge, LogSize*1024*1024)
case LogLevel
when :fatal then
  $logger.level = Logger::FATAL
when :error then
  $logger.level = Logger::ERROR
when :warn then
  $logger.level = Logger::WARN
when :info then
  $logger.level = Logger::INFO
when :debug then
  $logger.level = Logger::DEBUG
end

chatrec = CHATREC.new()

options = {
  :Port => SystemPort,
  :BindAddress => SystemBindAddress,
  :DoNotReverseLookup => true
}

if (UseSSL)
  options.store(:SSLEnable, true)
  options.store(:SSLVerifyClient, OpenSSL::SSL::VERIFY_NONE)
  options.store(:SSLCertificate, OpenSSL::X509::Certificate.new(open(SSLCertFile).read))
  options.store(:SSLPrivateKey, OpenSSL::PKey::RSA.new(open(SSLCertKeyFile).read))
  options.store(:SSLOptions, OpenSSL::SSL::OP_ALL | OpenSSL::SSL::OP_NO_SSLv2 | OpenSSL::SSL::OP_IGNORE_UNEXPECTED_EOF)
end

s = WEBrick::HTTPServer.new(options)

s.mount_proc('/'){|request, response|
  errormsg = "request body error."
  begin
    data = Hash::new

    if (request.request_method != "POST")
      errormsg = "HTTP method error."
      raise ArgumentError.new(errormsg)
    end
    if (request.content_type == nil)
      errormsg = "content-type error."
      raise ArgumentError.new(errormsg)
    end
    if (request.body == nil)
      errormsg = "request body error. bodysize=nil"
      raise ArgumentError.new(errormsg)
    end

    userInput = JSON.parse(request.body)
    mode = userInput["mode"]

    case mode
    when "run"
      $logger.info("connection: :#{request.peeraddr.to_s}")
      $logger.info("run")
      user_id = userInput["user_id"]
      query = userInput["query"]
      message = chatrec.run(query, user_id)
      data["message"] = message
      response.body = JSON.generate(data)
    when "clear"
      $logger.info("connection: :#{request.peeraddr.to_s}")
      $logger.info("clear")
      user_id = userInput["user_id"]
      chatrec.clear(user_id)
      response.body = JSON.generate({})
    when "stop"
      $logger.info("connection: :#{request.peeraddr.to_s}")
      $logger.info("stop")
      chatrec.close()
      response.body = JSON.generate({})
    when "history"
      $logger.info("connection: :#{request.peeraddr.to_s}")
      $logger.info("history")
      user_id = userInput["user_id"]
      message = chatrec.load_history(user_id)
      data["message"] = message
      response.body = JSON.generate(data)
    end

  rescue Exception => e
    $logger.fatal(e.message)
    $logger.fatal(e.class)
    $logger.fatal e.backtrace
    errdata = Hash::new
    errbody = Hash::new
    case e
    when Net::ReadTimeout then
      response.status = 408
    when Net::ProtoAuthError then
      response.status = 401
    else
      response.status = 500
    end
    errbody["query"] = response.status
    errbody["message"] = e.message
    errdata["error"] = errbody
    response.body = JSON.generate(errdata)
  ensure
    if (HTTPAccessControl != nil && HTTPAccessControl != "")
      response.header["Access-Control-Allow-Origin"] = HTTPAccessControl
    end
    response.content_type = "application/json; charset=UTF-8"
  end
}

Signal.trap(:INT){
  s.shutdown
}

s.start
chatrec.close()

