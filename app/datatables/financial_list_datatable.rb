class FinancialListDatatable < AjaxDatatablesRails::Base
  include AjaxDatatablesRails::Extensions::Kaminari
  def_delegators :@view,:link_to, :h, :mailto, :other_method
  def sortable_columns
    # Declare strings in this format: ModelName.column_name
    @sortable_columns ||= %w(Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name)
  end

  def searchable_columns
    # Declare strings in this format: ModelName.column_name
    @searchable_columns ||= %w(Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name Company.first_name)
  end

  private

  def data
    outer = []
    records.each_with_index  do |record, index|
      outer << [
          # comma separated list of the values for each cell of a table row
          # example: record.attribute,
          index + 1 + params[:start].to_i,
          record.company_name,
          record.earning_from_subscription,
          record.earning_from_sms,
          record.businesses.count,
          record.revenue_total
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
