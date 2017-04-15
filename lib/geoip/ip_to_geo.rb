module Geoip
  class IpToGeo

    DB_PATH = "#{Rails.root}/lib/geoip/GeoLiteCity.dat"

    def timezone(ipv4)
      if ipv4.present?
        addr = IPAddr.new(ipv4.to_s.strip)
        32.downto(16).map do |mask| #if an address fails, test with enclosing network X.X.X.X , X.X.X.0 , X.X.0.0 ...
          network = addr.mask(mask).to_i
          c = db.city(network)
          if c && c.timezone
            return c.timezone
          end
        end
      end
      nil
    end

#a similar pattern can be re-used
    def country_code(ipv4)
      if ipv4.present?
        candidate = ipv4.to_s.strip
        addr = IPAddr.new(ipv4.to_s.strip)
        32.downto(16).map do |mask|
          network = addr.mask(mask).to_i
          c = db.city(network)
          if c && c.country_code2
            return c.country_code2
          end
        end
      end
      nil
    end

    def location(ipv4)
      if ipv4.present?
        candidate = ipv4.to_s.strip
        addr = IPAddr.new(ipv4.to_s.strip)
        32.downto(16).map do |mask|
          network = addr.mask(mask).to_i
          c = db.city(network)
          return c if c
        end
      end
      nil
    end


    def db
      @db ||= GeoIP.new(DB_PATH)
    end

  end
end