class CreateSettingPermissions < ActiveRecord::Migration
  def change
    create_table :setting_permissions do |t|
      t.text :setting_import
      t.text :setting_acnt
      t.text :setting_apntrem
      t.text :setting_apnttype
      t.text :setting_bill	
      t.text :setting_bsn
      t.text :setting_onbook
      t.text :setting_cns
      t.text :setting_docprint
      t.text :setting_ingrt
      t.text :setting_invcset
      t.text :setting_lettemp
      t.text :setting_pmttype
      t.text :setting_refsrc
      t.text :setting_smsset
      t.text :setting_sub
      t.text :setting_tax
      t.text :setting_tnt
      t.text :setting_userpract

      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
