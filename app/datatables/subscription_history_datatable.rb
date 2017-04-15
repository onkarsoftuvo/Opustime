class SubscriptionHistoryDatatable < AjaxDatatablesRails::Base
  include AjaxDatatablesRails::Extensions::Kaminari
  def_delegators :@view, :link_to, :h, :full_name,:image_tag,:timeZone_lookup

  def initialize(view, company_id=nil)
    super
    @company = Company.find_by_id(company_id)
  end

  def sortable_columns
    # Declare strings in this format: ModelName.column_name
    @sortable_columns ||= %w(Transaction.transaction_type Transaction.transaction_type Transaction.transaction_type Transaction.transaction_type Transaction.transaction_type Transaction.transaction_type )
  end

  def searchable_columns
    # Declare strings in this format: ModelName.column_name
    @searchable_columns ||= %w(Transaction.transaction_type Transaction.transaction_type Transaction.transaction_type Transaction.transaction_type Transaction.transaction_type Transaction.transaction_type )
  end

  private

  def data
    records.map.each_with_index do |record,index|
      [
          index + 1 + params[:start].to_i,
          record.plan.name,
          (Money.new(record.amount, 'USD')*100).format,
          record.plan.no_doctors,
          record.transaction_type.to_s.eql?('SA') ? 'Subscription Added (SA)' : 'Subscription Cancelled (SC)',
          record.created_at.utc.in_time_zone(timeZone_lookup(@company.time_zone)).strftime('%A, %d %b %Y %l:%M %p'),
          link_to('<i class="fa fa-eye"></i>'.html_safe, 'javascript:void(0);', :class => 'btn btn-warning', :onclick => "subscription_history(#{record.id})", :style => 'margin-bottom: 10px;margin-right: 5px;', :title => 'Inactive')
      ]
    end
  end

  def get_raw_records
    Transaction.where('company_id =? and transaction_type IN(?)',@company.id,['SA','SC']).order('created_at DESC')
  end

end
