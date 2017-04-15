class AddColumnSignatureLogoToUser < ActiveRecord::Migration
  def change
    add_attachment :users , :logo , default: nil
  end
end
