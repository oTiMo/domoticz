require 'cgi'
module Domoticz
  def self.log(message)
    perform_api_request "type=command&param=addlogmessage&message=#{CGI.escape(message)}"
  end
end
