json.extract! exchangerate, :id, :currency1_id, :currency2_id, :minrate, :currentrate, :maxrate, :created_at, :updated_at
json.url exchangerate_url(exchangerate, format: :json)
