class SettingPermission < ActiveRecord::Base
  include PermissionFormat

  belongs_to :owner

  serialize :setting_import
  serialize :setting_acnt
  serialize :setting_apntrem
  serialize :setting_apnttype
  serialize :setting_bill
  serialize :setting_bsn
  serialize :setting_onbook
  serialize :setting_cns
  serialize :setting_docprint
  serialize :setting_ingrt
  serialize :setting_invcset
  serialize :setting_lettemp
  serialize :setting_pmttype
  serialize :setting_refsrc
  serialize :setting_smsset
  serialize :setting_sub
  serialize :setting_tax
  serialize :setting_tnt
  serialize :setting_userpract
  serialize :setting_smstemp

  scope :specific_attr , ->{ select('setting_import , setting_acnt , setting_apntrem , setting_apnttype ,

setting_bill , setting_bsn , setting_onbook , setting_cns , setting_docprint , setting_ingrt , setting_invcset,
  setting_lettemp , setting_pmttype , setting_refsrc , setting_smsset , setting_sub , setting_tax , setting_tnt ,
 setting_userpract , setting_smstemp ')}
end
