# frozen_string_literal: true

module Domoticz
  def self.sunrise_sunset
    SunriseSunset.new_from_json(perform_api_request('type=command&param=getSunRiseSet'))
  end
  class SunriseSunset
    attr_accessor :data

    def method_missing(method_sym, *arguments, &block)
      hash = Hash[@data.map { |k, v| [k.downcase, v] }]
      key = method_sym.to_s.downcase

      if hash.key?(key)
        hash[key]
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
  end
end
