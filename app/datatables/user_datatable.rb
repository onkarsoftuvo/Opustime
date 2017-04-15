class UserDatatable < AjaxDatatablesRails::Base
  include AjaxDatatablesRails::Extensions::Kaminari
  def_delegators :@view, :link_to, :h, :full_name,:image_tag

  def sortable_columns
    # Declare strings in this format: ModelName.column_name
    @sortable_columns ||= ['owners.id','owners.logo_file_name','owners.first_name' ,'owners.email','owners.status','owners.role']
  end

  def searchable_columns
    # Declare strings in this format: ModelName.column_name
    @searchable_columns ||=['owners.id','owners.logo_file_name','owners.first_name' ,'owners.email','owners.status','owners.role']
  end

  private

  def data
    records.map.each_with_index do |record,index|
      [
          # comma separated list of the values for each cell of a table row
          # example: record.attribute,
          index + 1 + params[:start].to_i,
          record.logo.present? ? image_tag(record.logo.url(:thumb),:width => '50px',:height => '50px;') : image_tag('default_admin.png',:width => '50px',:height => '50px;'),
          record.full_name,
          record.email,
          record.status ? 'Active' : 'Inactive',
          record.role,
          if record.status
            link_to('<i class="fa fa-close"></i>'.html_safe, 'javascript:void(0);', :class => 'btn btn-warning', :onclick => "activate(#{record.id})", :style => 'margin-bottom: 10px;margin-right: 5px;', :title => 'Inactive')+
                link_to('<i class="fa fa-trash"></i>'.html_safe, 'javascript:void(0);', :class => 'btn btn-danger', :onclick => "destroy(#{record.id})", :style => 'margin-bottom: 10px;margin-right: 5px;', :title => 'Delete')
          else
            link_to('<i class="fa fa-check"></i>'.html_safe, 'javascript:void(0);', :class => 'btn btn-success', :onclick => "activate(#{record.id})", :style => 'margin-bottom: 10px;margin-right: 5px;', :title => 'Active')+
                link_to('<i class="fa fa-trash"></i>'.html_safe, 'javascript:void(0);', :class => 'btn btn-danger', :onclick => "destroy(#{record.id})", :style => 'margin-bottom: 10px;margin-right: 5px;', :title => 'Delete')
          end


      ]
    end
  end

  def get_raw_records
    # find all admin, sales and marketing users
    Owner.where('owners.role IN (?)', ['admin_user', 'sales_user', 'marketing_user']).order('created_at DESC')
  end

end
