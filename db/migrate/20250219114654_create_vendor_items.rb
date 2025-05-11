class CreateVendorItems < ActiveRecord::Migration[7.0]
  def change
    create_table :vendor_items do |t|
      t.string :title
      t.decimal :price
      t.string :url
      t.references :item, null: false, foreign_key: true
      t.string :vendor_name
      t.text :description

      t.timestamps
    end
  end
end
