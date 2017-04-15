class AddSmscreditToSmsSetting < ActiveRecord::Migration
  def change
    add_column :sms_settings , :default_sms , :integer , :dafault=> 5
  end
end
