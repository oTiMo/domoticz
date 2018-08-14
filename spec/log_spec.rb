# frozen_string_literal: true

require 'spec_helper'

describe Domoticz do
  describe ':log' do
    before(:each) do
      Domoticz.configure do |config|
        config.server = 'http://127.0.1.1:8080/'
        config.username = 'username'
        config.password = 'password'
        config.client_name = 'test_app'
      end
    end
    it 'send a log message to the server' do
      expect(Domoticz).to receive(:perform_api_request)
        .with('type=command&param=addlogmessage&message=test_app%3A+message')
      Domoticz.log 'message'
    end
    it 'can send non ascii message' do
      message = 'Il était une fois'
      expect(Domoticz).to receive(:perform_api_request)
        .with('type=command&param=addlogmessage&message=test_app%3A+Il+%C3%A9tait+une+fois')
      Domoticz.log message
    end
  end
end
