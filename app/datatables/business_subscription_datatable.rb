class BusinessSubscriptionDatatable < AjaxDatatablesRails::Base
  include AjaxDatatablesRails::Extensions::Kaminari
  def_delegators :@view, :link_to, :h, :timeZone_lookup,:full_name

  # def initialize(view, company_id=nil)
  #   super
  #   @company = Company.find_by_id(company_id)
  # end

  def sortable_columns
    # Declare strings in this format: ModelName.column_name
    @sortable_columns ||= %w(Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name)
  end

  def searchable_columns
    # Declare strings in this format: ModelName.column_name
    @searchable_columns ||=  %w(Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name)
  end

  private

  def data
    records.map.each_with_index do |record, index|
      [
          index + 1 + params[:start].to_i,
          record.id,
          record.full_name,
          record.subscription.name,
          (Money.new(record.subscription.cost, 'USD')*100).format,
          record.subscription.is_subscribed ? 'Subscribed' : 'Trial',
          record.subscription.created_at.utc.in_time_zone(timeZone_lookup(record.time_zone)).strftime('%A, %d %b %Y %l:%M %p'),
          link_to('<i class="fa fa-eye"></i>'.html_safe, "/business/#{record.id}/subscription_history", :class => 'btn btn-info', :style => 'margin-bottom: 10px;margin-right: 5px;', :title => 'History')
      ]
    end
  end

  def get_raw_records
    Company.all
  end

end
