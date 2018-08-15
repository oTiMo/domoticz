# frozen_string_literal: true

require "time-lord"

module Domoticz
  class Timer
    attr_accessor :idx
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
      timer = new
      timer.data = json
      timer.idx = json['idx'].to_i
      timer
    end

    def active?
      @data['Active'] == 'true'
    end

    EVERYDAY = 0x80
    WEEKDAYS = 0x100
    WEEKENDS = 0x200
    MONDAY = 0x01 | EVERYDAY | WEEKDAYS
    TUESDAY = 0x02 | EVERYDAY | WEEKDAYS
    WEDNESDAY = 0x04 | EVERYDAY | WEEKDAYS
    THURSDAY = 0x08 | EVERYDAY | WEEKDAYS
    FRIDAY = 0x10 | EVERYDAY | WEEKDAYS
    SATURDAY = 0x20 | EVERYDAY | WEEKENDS
    SUNDAY = 0x40 | EVERYDAY | WEEKENDS
    DAYS = %i(sunday monday tuesday wednesday thursday friday saturday).freeze
    DAY_FLAGS = Hash[
      DAYS.zip([SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY])
    ]
    def apply_to?(day)
      case day
      when Symbol
        (DAY_FLAGS[day] & @data['Days']) != 0
      when Time
        apply_to?(DAYS[day.wday])
      else
        raise "#{day.class}: unsupported type"
      end
    end

    def date_array
      date.split('-').map(&:to_i)
    end

    def time_array
      time.split(':').map(&:to_i)
    end

    BEFORE_SUNRISE = 0
    AFTER_SUNRISE = 1
    ON_TIME = 2
    BEFORE_SUNSET = 3
    AFTER_SUNSET = 4
    FIXED_DATE = 5

    def next_date(date = Time.now)
      case type
      when BEFORE_SUNRISE, AFTER_SUNRISE
        sunrise = Domoticz.sunrise_sunset.sunrise_array
        if ([date.hour, date.min] <=> sunrise).negative?
          Time.local(date.year, date.month, date.day, *sunrise)
        else
          Time.local(date.year, date.month, date.day, *sunrise) + 1.day
        end
      when BEFORE_SUNSET, AFTER_SUNSET
        sunset = Domoticz.sunrise_sunset.sunset_array
        if ([date.hour, date.min] <=> sunset).negative?
          Time.local(date.year, date.month, date.day, *sunset)
        else
          Time.local(date.year, date.month, date.day, *sunset) + 1.day
        end
      when ON_TIME
        c = Time.local(date.year, date.month, date.day, *time_array)
        while c < c + 7.days
          return c if date < c && apply_to?(c)
          c += 1.day
        end
      when FIXED_DATE
        c = Time.local(*(date_array + time_array))
        c if c > date
      end
    end

    private

    def data_hash
      Hash[@data.map { |k, v| [k.downcase, v] }]
    end
  end
end
