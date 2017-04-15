class PaymentHistoryDatatable < AjaxDatatablesRails::Base
  include AjaxDatatablesRails::Extensions::Kaminari
  def_delegators :@view, :link_to, :h, :full_name, :timeZone_lookup

  def initialize(view, company_id=nil)
    super
    @company = Company.find_by_id(company_id)
  end

  def sortable_columns
    # Declare strings in this format: ModelName.column_name
    @sortable_columns ||= %w(Transaction.transaction_type Transaction.transaction_type Transaction.transaction_type Transaction.transaction_type )
  end

  def searchable_columns
    # Declare strings in this format: ModelName.column_name
    @searchable_columns ||=%w(Transaction.transaction_type Transaction.transaction_type Transaction.transaction_type Transaction.transaction_type )
  end

  private

  def data
    records.map.each_with_index do |record, index|
      [
          index + 1 + params[:start].to_i,
          (Money.new(record.amount, 'USD')*100).format,
          if record.transaction_type.to_s.eql?('ISP') then
            'Initial Subscription Payment (ISP)'
          elsif record.transaction_type.to_s.eql?('RSP')
            'Recurring Subscription Payment (RSP)'
          else
            'SMS Payment (SP)'
          end,
          record.created_at.utc.in_time_zone(timeZone_lookup(@company.time_zone)).strftime('%A, %d %b %Y %l:%M %p'),
      ]
    end
  end

  def get_raw_records
    Transaction.where('company_id =? and transaction_type IN(?) and error_status=?', @company.id, ['ISP', 'SP', 'RSP'], false).order('created_at DESC')
  end

end
