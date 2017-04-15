class AddLogoToDocumentAndPrintings < ActiveRecord::Migration
  def up
    add_attachment :document_and_printings, :logo
  end

  def down
    remove_attachment :document_and_printings, :logo
  end
end
