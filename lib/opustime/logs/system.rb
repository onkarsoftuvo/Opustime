require 'will_paginate/array'
include Opustime::Logs::Common
module Opustime
  module Logs
    module System
      # fetch all logs of a specific company or its associated user by date
      # date format is like this 'yyyy-mm-dd'
      def sys_logs(company, user, page_no, per_page, start_date, end_date)

        if company.present? && user.present?
          total_pages, total_record, response = sys_user_logs_filter_by_start_date(company, user, start_date, page_no, per_page) if start_date.present?
          total_pages, total_record, response = sys_user_logs_filter_by_start_and_end_date(company, user, start_date, end_date, page_no, per_page) if start_date.present? && end_date.present?
        elsif company.present?
          total_pages, total_record, response = sys_company_logs_filter_by_start_date(company, start_date, page_no, per_page) if start_date.present?
          total_pages, total_record, response = sys_company_logs_filter_by_start_and_end_date(company, start_date, end_date, page_no, per_page) if start_date.present? && end_date.present?
        end
        return total_pages, total_record, response
      end

      private

      # all private method write here
      def sys_prepare_response(logs, logs_count, per_page, log_level,company=nil,user=nil)
        total_pages = (logs_count.to_f/per_page.to_i).ceil rescue nil
        serialized_logs = ActiveModel::Serializer::CollectionSerializer.new(logs, each_serializer: OpustimeLogSerializer,:log_level=>log_level,:company=>company,:user=>user).to_json
        logs.present? && total_pages.present? ? (return total_pages, logs_count, JSON.parse(serialized_logs)) : (return 0, 0, [])
      end

      def sys_user_logs_filter_by_start_date(company, user, start_date, page_no, per_page)
        logs = OpustimeLog.where('user_info like ? && date(created_at) = ?', "%#{company.id}-#{user.id}%", start_date).paginate(:page => page_no, :per_page => per_page).order('created_at DESC')
        logs_count = OpustimeLog.where('user_info like ? && date(created_at) = ?', "%#{company.id}-#{user.id}%", start_date).count
        sys_prepare_response(logs, logs_count, per_page, 'user_logs',company,user)
      end

      def sys_user_logs_filter_by_start_and_end_date(company, user, start_date, end_date, page_no, per_page)
        logs = OpustimeLog.where('user_info like ? && date(created_at) between ? and ?', "%#{company.id}-#{user.id}%", start_date, end_date).paginate(:page => page_no, :per_page => per_page).order('created_at DESC')
        logs_count = OpustimeLog.where('user_info like ? && date(created_at) between ? and ?', "%#{company.id}-#{user.id}%", start_date, end_date).count
        sys_prepare_response(logs, logs_count, per_page, 'user_logs',company,user)
      end

      def sys_company_logs_filter_by_start_date(company, start_date, page_no, per_page)
        logs = OpustimeLog.where('user_info like ? && date(created_at) = ?', "%#{company.id}-%", start_date).paginate(:page => page_no, :per_page => per_page).order('created_at DESC')
        logs_count = OpustimeLog.where('user_info like ? && date(created_at) = ?', "%#{company.id}-%", start_date).count
        sys_prepare_response(logs, logs_count, per_page, 'company_logs',company)
      end

      def sys_company_logs_filter_by_start_and_end_date(company, start_date, end_date, page_no, per_page)
        logs = OpustimeLog.where('user_info like ? && date(created_at) between ? and ?', "%#{company.id}-%", start_date, end_date).paginate(:page => page_no, :per_page => per_page).order('created_at DESC')
        logs_count = OpustimeLog.where('user_info like ? && date(created_at) between ? and ?', "%#{company.id}-%", start_date, end_date).count
        sys_prepare_response(logs, logs_count, per_page, 'company_logs',company)
      end

    end
  end
end