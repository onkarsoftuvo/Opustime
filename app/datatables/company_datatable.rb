class CompanyDatatable < AjaxDatatablesRails::Base
  include AjaxDatatablesRails::Extensions::Kaminari
  def_delegators :@view, :link_to, :h, :mailto, :other_method

  def sortable_columns
    # Declare strings in this format: ModelName.column_name
    @sortable_columns ||= %w(Company.id  Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name)
  end

  def searchable_columns
    # Declare strings in this format: ModelName.column_name
    @searchable_columns ||= %w(Company.first_name Company.first_name Company.first_name)
  end

  private

  def data
    outer = []
    records.each_with_index do |record, index|
      outer << [
        # comma separated list of the values for each cell of a table row
        # example: record.attribute,
          index + 1+ params[:start].to_i,
          record.company_name,
          record.try(:account).try(:owner),
          record.businesses.count,
          record.users.doctors.count,
          record.revenue_total.round(2),
          record.status,
          link_to('<i class="fa fa-edit"></i>'.html_safe, 'javascript:void(0);', :id => 'btnView',:class => 'btn btn-success',:onclick => "open_edit_form(#{record.id})", :style => 'margin-bottom: 10px;margin-right: 5px;', :title => 'View') +
          link_to('<i class="fa fa-credit-card"></i>'.html_safe, 'javascript:void(0);', :class => 'btn btn-danger',:onclick => "sms_edit(#{record.id})", :style => 'margin-bottom: 10px;margin-right: 5px;', :title => 'Show')

      ]

    end
    outer
  end

  def get_raw_records
    Company.all
  end

  # ==== Insert 'presenter'-like methods below if necessary
end
