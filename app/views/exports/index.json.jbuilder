json.array!(@exports) do |export|
  json.extract! export, :id, :ex_type, :ex_date_range, :company_id
  json.url export_url(export, format: :json)
end
