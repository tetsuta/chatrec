#!/usr/bin/env ruby
# coding: utf-8

require 'getoptlong'
require 'webrick'
require 'webrick/https'
require 'net/protocol'
require 'logger'

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
      $logger.info("getAllReport")
      user_id = userInput["user_id"]
      query = userInput["query"]
      message = chatrec.run(query, user_id)
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

