json.array!(@imports) do |import|
  json.extract! import, :id, :file_name, :import_type, :status, :show_delete, :company_id
  json.url import_url(import, format: :json)
end
