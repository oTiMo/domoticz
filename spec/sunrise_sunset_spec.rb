# frozen_string_literal: true

require 'spec_helper'

describe Domoticz::SunriseSunset do
  describe '::new_from_json' do
    it 'can create object from a json definition' do
      json = JSON.parse(IO.read('spec/fixtures/sunrise_sunset.json'))
      expect(
        Domoticz::SunriseSunset.new_from_json(json)
      ).to be_a(Domoticz::SunriseSunset)
    end
  end
  subject do
    json = JSON.parse(IO.read('spec/fixtures/sunrise_sunset.json'))
    Domoticz::SunriseSunset.new_from_json(json)
  end
  describe '#data' do
    it 'is the full setting map' do
      expect(subject.data).to eq(
        'ServerTime' => '2016-02-22 23:00:23',
        'Sunrise' => '07:28',
        'Sunset' => '18:11',
        'status' => 'OK',
        'title' => 'getSunRiseSet'
      )
    end
  end
  describe '#sunrise_array' do
    it 'returns an array [hour, minute]' do
      expect(subject.sunrise_array).to eq([7, 28])
    end
  end
  describe '#sunset_array' do
    it 'returns an array [hour, minute]' do
      expect(subject.sunset_array).to eq([18, 11])
    end
  end
end
