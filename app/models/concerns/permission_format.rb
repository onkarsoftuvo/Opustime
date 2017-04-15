module PermissionFormat
  extend ActiveSupport::Concern

  module ClassMethods

    # Formatting keys values for permission matrix for all permission matrix models

    def get_exact_values
      owner = Owner.find_by_role('super_admin_user')
      pm_model = self.specific_attr.find_by_owner_id(owner.id)
      tb_attr = pm_model.attributes
      new_hash = {}
      tb_attr.each do |key , val |
        unless val.nil?
          item = {}
          val.each do |sub_key , sub_val|
            item[sub_key.gsub(' ','_')] = sub_val.to_bool
          end
          new_hash[key] = item
        end
      end
      return new_hash
    end

  end

end
