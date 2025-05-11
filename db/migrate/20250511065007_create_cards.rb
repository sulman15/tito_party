class CreateCards < ActiveRecord::Migration[7.0]
  def change
    create_table :cards do |t|
      t.string :heading
      t.string :company_name
      t.text :details
      t.string :href
      t.string :logo

      t.timestamps
    end
  end
end
