class DashboardPermission < ActiveRecord::Base
  include PermissionFormat

  belongs_to :owner

  serialize :dashboard_top , JSON
  serialize :dashboard_report , JSON
  serialize :dashboard_appnt , JSON
  serialize :dashboard_activity , JSON
  serialize :dashboard_chartpracti , JSON
  serialize :dashboard_chartproduct , JSON

  scope :specific_attr , ->{ select('dashboard_top, dashboard_report , dashboard_appnt , dashboard_activity ,dashboard_chartpracti , dashboard_chartproduct')}

  # def get_exact_values
  #   tb_attr = self.attributes
  #   new_hash = {}
  #   tb_attr.each do |key , val |
  #     unless val.nil?
  #       item = {}
  #       val.each do |sub_key , sub_val|
  #         item[sub_key.gsub(' ','_')] = sub_val.to_bool
  #       end
  #       new_hash[key] = item
  #     end
  #   end
  #   return new_hash
  # end


end
