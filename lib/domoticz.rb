# frozen_string_literal: true

require 'domoticz/version'
require 'domoticz/configuration'
require 'domoticz/device'
require 'json'
require 'domoticz/timer'
require 'domoticz/sunrise_sunset'
require 'domoticz/log'
require 'net/http'

module Domoticz
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.perform_api_request(params)
    response = get_api_response(params)
    JSON.parse(response.body)
  end

  def self.username
    Domoticz.configuration.username
  end

  def self.password
    Domoticz.configuration.password
  end

  class << self
    private

    def get_api_response(params)
      uri = URI(Domoticz.configuration.server + 'json.htm?' + params)

      request = get_request(uri)

      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: uri.scheme == 'https',
      ) { |http| http.request(request) }

      response
    end

    def get_request(uri)
      request = Net::HTTP::Get.new(uri)
      request.basic_auth(username, password) if username && password
      request
    end
  end
end
