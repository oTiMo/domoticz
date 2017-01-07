module Domoticz
  class Device
    attr_accessor :idx
    attr_accessor :data

    def on!
      Domoticz.perform_api_request("type=command&param=switchlight&idx=#{idx}&switchcmd=On")
    end

    def off!
      Domoticz.perform_api_request("type=command&param=switchlight&idx=#{idx}&switchcmd=Off")
    end

    def toggle!
      Domoticz.perform_api_request("type=command&param=switchlight&idx=#{idx}&switchcmd=Toggle")
    end

    def timers
      if @data['Timers'] || @data['Timers'] == 'true'
        Domoticz.perform_api_request("type=timers&idx=#{idx}")['result'].map{|t| Timer.new_from_json(t)}
      end
    end

    LightRecord = Struct.new(:date, :data, :status, :level, :max_dim_level)
    def lightlog
      Domoticz.perform_api_request("type=lightlog&idx=#{idx}")['result'].map do |t| 
        LightRecord.new(t['Date'], t['Data'], t['Status'], t['Level'], t['MaxDimLevel'])
      end
    end

    TempRecord = Struct.new(:date, :temperature, :humidity, :temp_min, :temp_max)
    TEMP_LOG_RANGE = [:day, :month, :year]
    def templog(range=TEMP_LOG_RANGE.first)
      Domoticz.perform_api_request("type=graph&sensor=temp&idx=#{idx}&range=#{range}")['result'].map do |t|
        TempRecord.new(
          t['d'],
          range == :day ? t['te'] : t['ta'],
          t['hu'] ? Integer(t['hu']) : nil,
          t['tm'],
          range == :day ? nil : t['te']
        )
      end
    end

    TimerDate = Struct.new(:timer, :date)
    def next_timers(date = DateTime.now)
      sorted = timers
        .map{|t| TimerDate.new(t, t.next_date(date))}
        .select(&:date) # remove event without next date
        .sort_by(&:date)
      first = sorted[0]
      sorted.take_while{|t| t.date == first.date}.to_a
    end

    def enum_next_timers(date = DateTime.now)
      return enum_for(:enum_next_timers, date).lazy unless block_given?
      while true
        timers = next_timers(date)
        break if timers.empty?
        timers.each { |t| yield t }
        date = timers.first.date
      end
    end

    def temperature
      temp
    end

    def dimmer?
      isDimmer
    end

    def respond_to?(method_sym)
      data.has_key?(method_sym.to_s.downcase) || super
    end

    def method_missing(method_sym, *arguments, &block)
      hash = Hash[@data.map { |k, v| [k.downcase, v] }]
      key = method_sym.to_s.downcase

      if hash.has_key?(key)
        hash[key]
      else
        super
      end
    end

    def self.find_by_id(id)
      all.find { |d| d.idx == id }
    end

    def self.all
      Domoticz.perform_api_request("type=devices&filter=all&used=true")["result"].map do |json|
        Device.new_from_json(json)
      end
    end

    def self.device(id)
      Domoticz.perform_api_request("type=devices&rid=#{id}")['result'].map do |json|
        Device.new_from_json(json)
      end.first
    end

    def self.new_from_json(json)
      device = self.new
      device.data = json
      device.idx = json["idx"].to_i
      device
    end
  end
end
