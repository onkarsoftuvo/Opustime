class AddLogoToOwners < ActiveRecord::Migration
  def change
    add_attachment :owners, :logo
  end
end
