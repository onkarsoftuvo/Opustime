class BusinessCustomerDatatable < AjaxDatatablesRails::Base
  include AjaxDatatablesRails::Extensions::Kaminari
  def_delegators :@view, :link_to, :h, :mailto, :other_method,:customer_last_week, :customer_last_month
  def sortable_columns
    # Declare strings in this format: ModelName.column_name
    @sortable_columns ||= %w(Company.first_name Company.first_name Company.first_name Company.first_name)
  end

  def searchable_columns
    # Declare strings in this format: ModelName.column_name
    @searchable_columns ||= %w(Company.first_name Company.first_name Company.first_name Company.first_name)
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
          customer_last_week(record).count,
          customer_last_month(record).count,
          link_to('<i class="fa fa-eye"></i>'.html_safe, 'javascript:void(0);', :id => 'btnView',:class => 'btn btn-success',:onclick => "open_edit_form(#{record.id})", :style => 'margin-bottom: 10px;margin-right: 5px;', :title => 'View')
      ]
    end
    outer
  end

  def get_raw_records
    Company.all
    # insert query here
  end

  # ==== Insert 'presenter'-like methods below if necessary
end
