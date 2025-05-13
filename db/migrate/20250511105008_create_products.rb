class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :title
      t.string :url
      t.string :icon
      t.string :company
      t.text :description
      t.references :subcategory, null: false, foreign_key: true

      t.timestamps
    end
  end
end
