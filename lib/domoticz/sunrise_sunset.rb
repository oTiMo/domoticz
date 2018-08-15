# frozen_string_literal: true

module Domoticz
  def self.sunrise_sunset
    SunriseSunset.new_from_json(
      perform_api_request('type=command&param=getSunRiseSet'),
    )
  end
  class SunriseSunset
    attr_accessor :data

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

    def self.new_from_json(json)
      srst = new
      srst.data = json
      srst
    end

    def sunrise_array
      sunrise.split(':').map(&:to_i)
    end

    def sunset_array
      sunset.split(':').map(&:to_i)
    end

    private

    def data_hash
      Hash[@data.map { |k, v| [k.downcase, v] }]
    end
  end
end
