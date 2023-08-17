json.extract! wareobject, :id, :type, :price, :quantity, :wareshelf_id, :wareobject_id, :created_at, :updated_at
json.url wareobject_url(wareobject, format: :json)
