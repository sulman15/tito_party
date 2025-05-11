class CreateSubheadings < ActiveRecord::Migration[7.0]
  def change
    create_table :subheadings do |t|
      t.string :title
      t.string :href
      t.references :heading, null: false, foreign_key: true

      t.timestamps
    end
  end
end
