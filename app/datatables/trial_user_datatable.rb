class TrialUserDatatable < AjaxDatatablesRails::Base
  include AjaxDatatablesRails::Extensions::Kaminari
  def_delegators :@view, :link_to, :h, :mailto, :other_method, :total_days
  def sortable_columns
    # Declare strings in this format: ModelName.column_name
    @sortable_columns ||= %w(Company.first_name  Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name)
  end

  def searchable_columns
    # Declare strings in this format: ModelName.column_name
    @searchable_columns ||= %w(Company.first_name  Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name)
  end

  private

  def data
    outer = []
    records.each_with_index do |record, index|
      outer << [
          # comma separated list of the values for each cell of a table row
          # example: record.attribute,
          index + 1 + params[:start].to_i,
          record.company_name,
          record.patients.count,
          record.try(:lastlogin).try(:strftime, '%A, %d %b %Y %l:%M %p'),
          record.subscription.purchase_date.try(:strftime, '%A, %d %b %Y %l:%M %p'),
          record.subscription.try(:end_date),
          total_days(record.subscription.try(:end_date), Time.zone.now),
          record.subscription.try(:name),
              link_to('<i class="fa fa-credit-card"></i>'.html_safe, 'javascript:void(0);', :class => 'btn btn-danger',:onclick => "day_edit(#{record.id})", :style => 'margin-bottom: 10px;margin-right: 5px;', :title => 'Show')
      ]
    end
    outer
  end

  def get_raw_records
    Company.joins(:subscription).where('subscriptions.is_subscribed=?',false)
    # insert query here
  end

end
