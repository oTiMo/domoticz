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

    def value=(value)
      Domoticz.perform_api_request(update_value_request(value))
    end

    def timers
      if @data['Timers'] || @data['Timers'] == 'true'
        Domoticz.perform_api_request("type=timers&idx=#{idx}")['result']
                .map { |t| Timer.new_from_json(t) }
      end
    end

    LightRecord = Struct.new(:date, :data, :status, :level, :max_dim_level)
    def lightlog
      Domoticz.perform_api_request("type=lightlog&idx=#{idx}")['result']
              .map do |t|
                LightRecord.new(
                  t['Date'],
                  t['Data'],
                  t['Status'],
                  t['Level'],
                  t['MaxDimLevel'],
                )
              end
    end

    TempRecord = Struct.new(
      :date,
      :temperature,
      :humidity,
      :temp_min,
      :temp_max,
    )
    TEMP_LOG_RANGE = %i(day month year).freeze
    def templog(range = TEMP_LOG_RANGE.first)
      Domoticz.perform_api_request(templog_request(range))['result']
              .map do |t|
                TempRecord.new(
                  t['d'],
                  range == :day ? t['te'] : t['ta'],
                  t['hu'] ? Integer(t['hu']) : nil,
                  t['tm'],
                  range == :day ? nil : t['te'],
                )
              end
    end

    TimerDate = Struct.new(
      :timer,
      :date,
    )
    def next_timers(date = Time.now)
      sorted = timers.map { |t| TimerDate.new(t, t.next_date(date)) }
                     .select(&:date) # remove event without next date
                     .sort_by(&:date)
      first = sorted[0]
      sorted.take_while { |t| t.date == first.date }.to_a
    end

    def enum_next_timers(date = Time.now)
      return enum_for(:enum_next_timers, date).lazy unless block_given?
      loop do
        timers = next_timers(date)
        break if timers.empty?
        timers.each { |t| yield t }
        date = timers.first.date
      end
    end

    Schedule = Struct.new(:date, :data)
    def next_schedule
      date = Time.now
      result = Domoticz.perform_api_request('type=schedules')['result']

      return nil unless result

      result.select { |t| (t['RowID'] || t['DeviceRowID']).to_i == idx && t['Active'] == 'true' }
            .map { |t| Schedule.new(Time.strptime(t['ScheduleDate'], '%Y-%m-%d %H:%M:%S'), t) }
            .select { |s| s.date > date }
            .min_by(&:date)
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

    def self.find_by(idx:)
      all.find { |d| d.idx == idx }
    end

    def self.all
      Domoticz.perform_api_request(device_list_request)['result'].map do |json|
        Device.new_from_json(json)
      end
    end

    def self.device(id)
      Domoticz.perform_api_request("type=devices&rid=#{id}")['result']
              .map do |json|
                Device.new_from_json(json)
              end.first
    end

    def self.new_from_json(json)
      device = new
      device.data = json
      device.idx = json['idx'].to_i
      device
    end

    def self.create_sensor(name)
      idx = Domoticz.perform_api_request(create_sensor_request(name))['idx']
      device(idx)
    end

    def self.dummy_hardware
      Domoticz.perform_api_request('type=hardware')['result']
              .find { |h| h['Name'] == 'Dummy' }
    end

    private

    def data_hash
      Hash[@data.map { |k, v| [k.downcase, v] }]
    end

    def switch_cmd_request(cmd)
      "type=command&param=switchlight&idx=#{idx}&switchcmd=#{cmd.capitalize}"
    end

    def create_sensor_request(name)
      dh = dummy_hardware['idx']
      "type=createvirtualsensor&idx=#{dh}&sensorname=#{name}&sensortype=1004&sensoroptions=1;unit"
    end

    def update_value_request(value)
      "type=command&param=udevice&idx=#{idx}&nvalue=0&svalue=#{value}"
    end

    def templog_request(range)
      "type=graph&sensor=temp&idx=#{idx}&range=#{range}"
    end

    class << self
      private

      def device_list_request
        'type=devices&filter=all&used=true'
      end
    end
  end
end
