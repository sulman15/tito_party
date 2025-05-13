require 'csv'

class CsvExporter
  def self.export_categories_with_subcategories_and_products
    CSV.generate(headers: true) do |csv|
      csv << ['Category Title', 'Category URL', 'Category Description', 'Subcategory Title', 'Subcategory URL', 'Product Title', 'Product URL', 'Product Icon', 'Product Company', 'Product Description']

      Category.includes(subcategories: :products).find_each do |category|
        category.subcategories.each do |subcategory|
          subcategory.products.each do |product|
            csv << [
              category.title,
              category.url,
              category.description,
              subcategory.title,
              subcategory.url,
              product.title,
              product.url,
              product.icon,
              product.company,
              product.description
            ]
          end
        end
      end
    end
  end
end
