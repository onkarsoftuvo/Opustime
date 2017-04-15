class BusinessPaymentDatatable < AjaxDatatablesRails::Base
  include AjaxDatatablesRails::Extensions::Kaminari
  def_delegators :@view, :link_to, :h, :timeZone_lookup,:full_name


  def sortable_columns
    # Declare strings in this format: ModelName.column_name
    @sortable_columns ||= %w(Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name)
  end

  def searchable_columns
    # Declare strings in this format: ModelName.column_name
    @searchable_columns ||= %w(Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name)
  end

  private

  def data
    records.map.each_with_index do |record, index|
      [
          index + 1 + params[:start].to_i,
          record.id,
          record.full_name,
          (Money.new(total_sms_payment('SP',record.id), 'USD')*100).format,
          (Money.new(total_plan_payment(%w(ISP RSP),record.id), 'USD')*100).format,
          link_to('<i class="fa fa-eye"></i>'.html_safe, "/business/#{record.id}/payment_history", :class => 'btn btn-info', :style => 'margin-bottom: 10px;margin-right: 5px;', :title => 'History')
      ]
    end
  end

  def get_raw_records
    Company.all
  end

  def total_sms_payment(transaction_type,company_id)
    get_all_payment(transaction_type,company_id).map(&:amount).inject(0){|sum,val| sum+val.to_f}
  end

  def total_plan_payment(transaction_type,company_id)
    get_all_payment(transaction_type,company_id).map(&:amount).inject(0){|sum,val| sum+val.to_f}
  end

  def get_all_payment(transaction_type,company_id)
    if transaction_type.class.to_s.eql?('Array')
      Transaction.where('company_id =? and transaction_type IN(?) and error_status=?',company_id,transaction_type,false).order('created_at DESC')
    else
      Transaction.where('company_id =? and transaction_type =? and error_status=?',company_id,transaction_type,false).order('created_at DESC')
    end
  end

end
