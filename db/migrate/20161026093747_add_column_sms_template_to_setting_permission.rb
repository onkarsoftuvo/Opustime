class AddColumnSmsTemplateToSettingPermission < ActiveRecord::Migration
  def change
    add_column :setting_permissions , :setting_smstemp , :text
  end
end
