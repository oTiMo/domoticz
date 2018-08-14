# frozen_string_literal: true

require 'cgi'
module Domoticz
  def self.log(message)
    m = "#{Domoticz.configuration.client_name}: #{message}".b
    perform_api_request "type=command&param=addlogmessage&message=#{CGI.escape(m)}"
  end
end
