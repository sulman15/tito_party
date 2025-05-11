class CreateHeadings < ActiveRecord::Migration[7.0]
  def change
    create_table :headings do |t|
      t.string :title

      t.timestamps
    end
  end
end
