module Domoticz
  class Configuration
    attr_accessor :client_name
    attr_accessor :server
    attr_accessor :username
    attr_accessor :password

    def initialize
      self.server = "http://127.0.0.1:8080/"
      self.client_name = 'ruby_domoticz'
    end
  end
end
