#!/usr/bin/env ruby
# coding: utf-8

require 'getoptlong'
require 'leveldb'
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

chatrec_set = {}
chatrec = nil

history_db = LevelDB::DB.new(HistoryFile)


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

def chatrec_status(chatrec_set)
  buffer = []
  buffer.push("size: #{chatrec_set.size}")
  chatrec_set.each_pair{|user_id, chatrec|
    buffer.push("---")
    buffer.push(chatrec.status)
  }
  return buffer.join("\n")
end


def delete_old_connection(chatrec_set)
  buffer = []
  buffer.push("deleted:")
  chatrec_set.each_pair{|user_id, chatrec|
    if chatrec.age > ConnectionLifeSec
      buffer.push("#{user_id}\tage:#{chatrec.age}")
      chatrec_set.delete(user_id)
    end
  }
  return buffer.join("\n")
end


def generate_rand_key(num)
  charlist = ('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a
  buffer = ""
  1.upto(num){
    buffer << charlist[rand(charlist.size)]
  }
  return buffer
end


# --------------------------------------------------
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


    if mode == "status"
      $logger.info("connection: :#{request.peeraddr.to_s}")
      $logger.info("status")
      message = chatrec_status(chatrec_set)
      data["message"] = message
      response.body = JSON.generate(data)

    elsif mode == "delete"
      $logger.info("connection: :#{request.peeraddr.to_s}")
      $logger.info("delete")
      message = delete_old_connection(chatrec_set)
      data["message"] = message
      response.body = JSON.generate(data)

    else

      session_id = userInput["session_id"]
      if session_id == nil
        session_id = generate_rand_key(8)
        $logger.info("session generated: #{session_id}")
      else
        $logger.info("session existed: #{session_id}")
      end
      user_id = userInput["user_id"] + "__" + session_id

      if chatrec_set.has_key?(user_id)
        # puts "111:used"
        chatrec = chatrec_set[user_id]
      elsif user_id != nil
        # puts "111:create"
        chatrec = CHATREC.new(user_id, history_db)
        chatrec_set[user_id] = chatrec
        # puts "size: #{chatrec_set.size}"
      end

      data["session_id"] = session_id

      case mode
      when "run"
        $logger.info("connection: :#{request.peeraddr.to_s}")
        $logger.info("run")
        query = userInput["query"]
        message = chatrec.run(query)
        data["message"] = message
        response.body = JSON.generate(data)
      when "clear"
        $logger.info("connection: :#{request.peeraddr.to_s}")
        $logger.info("clear")
        chatrec.clear()
        response.body = JSON.generate(data)
      when "history"
        $logger.info("connection: :#{request.peeraddr.to_s}")
        $logger.info("history")
        message = chatrec.load_history()
        data["message"] = message
        response.body = JSON.generate(data)
      end
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

puts "closing DB..."
history_db.close
puts "done"

