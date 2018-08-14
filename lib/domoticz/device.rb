# frozen_string_literal: true

module Domoticz
  class Device
    attr_accessor :idx
    attr_accessor :data

    def seconds_since_update
      Time.now - Time.parse(lastupdate)
    end

    def on!
      Domoticz.perform_api_request(switch_cmd_request(:on))
    end

    def off!
      Domoticz.perform_api_request(switch_cmd_request(:off))
    end

    def toggle!
      Domoticz.perform_api_request(switch_cmd_request(:toggle))
    end

    def temperature
      temp
    end

    def dimmer?
      isDimmer
    end

    def method_missing(method_sym, *arguments, &block)
      key = method_sym.to_s.downcase

      if data_hash.key?(key)
        data_hash[key]
      else
        super
      end
    end

    def respond_to_missing?(method_sym, include_private)
      key = method_sym.to_s.downcase

      if data_hash.key?(key)
        data_hash[key]
      else
        super
      end
    end

    def self.find_by_idx(idx)
      all.find { |d| d.idx == idx.to_s }
    end

    def self.all
      Domoticz.perform_api_request(device_list_request)['result'].map do |json|
        Device.new_from_json(json)
      end
    end

    def self.new_from_json(json)
      device = new
      device.data = json
      device.idx = json['idx']
      device
    end

    private

    def data_hash
      Hash[@data.map { |k, v| [k.downcase, v] }]
    end

    def switch_cmd_request(cmd)
      "type=command&param=switchlight&idx=#{idx}&switchcmd=#{cmd.capitalize}"
    end

    class << self
      private

      def device_list_request
        'type=devices&filter=all&used=true'
      end
    end
  end
end
