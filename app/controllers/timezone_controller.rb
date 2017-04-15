class TimezoneController < ApplicationController

  def show
    result = []
    grouped_time_zone = OpusTimezone.all.sort_by{|object| -object.offset.to_i}.group_by(&:timezone_name)
    grouped_time_zone.each { |key, val| result.push({:time_zone => key, :printable_string => JSON.parse(ActiveModel::Serializer::CollectionSerializer.new(val, each_serializer: OpusTimezoneSerializer).to_json)}) }
    render :json => {:data=>result}
  end

end
