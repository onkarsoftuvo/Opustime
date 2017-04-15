module Opustime
  module Logs
    module Admin
      # fetch all logs of a specific company or its associated user by date
      # date format is like this 'yyyy-mm-dd'
      def admin_logs(page_no, per_page, start_date, end_date)
        total_pages, total_record, response = admin_logs_filter_by_start_date(start_date, page_no, per_page) if start_date.present?
        total_pages, total_record, response = admin_logs_filter_by_start_and_end_date(start_date, end_date, page_no, per_page) if start_date.present? && end_date.present?
        return total_pages, total_record, response
      end

      private

      # all private method write here
      def admin_prepare_response(logs, logs_count, per_page)
        total_pages = (logs_count.to_f/per_page.to_i).ceil rescue nil
        serialized_logs = ActiveModel::Serializer::CollectionSerializer.new(logs, each_serializer: OpustimeLogSerializer).to_json
        logs.present? && total_pages.present? ? (return total_pages, logs_count, JSON.parse(serialized_logs)) : (return 0, 0, [])
      end


      def admin_logs_filter_by_start_date(start_date, page_no, per_page)
        logs = OpustimeLog.where('user_info = ? && date(created_at) = ?', 'Anonymous', start_date).paginate(:page => page_no, :per_page => per_page).order('created_at DESC')
        logs_count = OpustimeLog.where('user_info = ? && date(created_at) = ?', 'Anonymous', start_date).count
        admin_prepare_response(logs, logs_count, per_page)
      end

      def admin_logs_filter_by_start_and_end_date(start_date, end_date, page_no, per_page)
        logs = OpustimeLog.where('user_info = ? && date(created_at) between ? and ?', 'Anonymous', start_date, end_date).paginate(:page => page_no, :per_page => per_page).order('created_at DESC')
        logs_count = OpustimeLog.where('user_info = ? && date(created_at) between ? and ?', 'Anonymous', start_date, end_date).count
        admin_prepare_response(logs, logs_count, per_page)
      end
    end
  end
end