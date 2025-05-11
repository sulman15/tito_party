class CreateWebsiteContents < ActiveRecord::Migration[7.0]
  def change
    create_table :website_contents do |t|
      t.references :website, null: false, foreign_key: true
      t.string :title
      t.text :raw_html
      t.text :body_text

      t.timestamps
    end
  end
end
