ROM::SQL.migration do
  change do
    create_table :albums do
      primary_key :id

      String :name, null: false
      String :cover_photo_data, null: false

      Time :created_at, null: false
      Time :updated_at, null: false
    end
  end
end
