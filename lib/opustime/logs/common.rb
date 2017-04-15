module Opustime
  module Logs
    module Common

      def company_associated_users(company)
        result = []
        users = company.users
        users.each do |user|
          user_object = user
          user = user.as_json
          user['full_name'] = user_object.full_name.to_s+' '+"(#{user_object.role})"
          result.push(user)
        end
        return result.to_json
      end

      def all_companies
        return JSON.parse(ActiveModel::Serializer::CollectionSerializer.new(Company.all, each_serializer: CompanySerializer).to_json)
      end

      def validate_date_format(date)
        begin
          is_parseable = Date.parse(date).present?
          if is_parseable
            spitted_date_array = date.to_s.split('-')
            (validate_year(spitted_date_array[0]) && validate_month(spitted_date_array[1]) && validate_day(spitted_date_array[2])) ? (return true, 'format is valid') : (return false, 'invalid date format')
          end
        rescue ArgumentError => error
          # handle invalid date
          return false, error.message
        end
      end

      private

      def validate_month(month)
        return (month.length == 2) && (month.to_i <=12)
      end

      def validate_day(day)
        return (day.length == 2) && (day.to_i <=31)
      end

      def validate_year(year)
        return year.length == 4
      end

    end
  end
end