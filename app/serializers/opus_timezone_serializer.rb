class OpusTimezoneSerializer < ActiveModel::Serializer
  attributes :formatted_timezone

  def formatted_timezone
     cities = ''
    object.all_cities.each { |city| cities.concat(city).concat(',') }
     cities.slice!(cities.length-1)
    return "UTC(#{object.offset}) #{cities}"
  end
end
