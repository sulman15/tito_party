class SyncDataJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "SyncDataJob started"
    scraper = CategoryScraper.new

    # Call the scrape method to get all data
    data = scraper.scrape('https://www.vendr.com/categories') # Replace with the actual URL

    Rails.logger.info "Data scraped: #{data.inspect}"

    # Store or update the data in the database
    data.each do |category_data|
      # Find or initialize category
      category = Category.find_or_initialize_by(title: category_data[:title])
      category.url = category_data[:url] # Set the URL
      category.description = category_data[:description] # Set the description
      category.save # Save the category

      category_data[:subheadings].each do |subheading|
        # Find or initialize subheading
        subheading_record = category.subcategories.find_or_initialize_by(title: subheading[:title])
        subheading_record.url = subheading[:href] # Set the URL for subheading
        subheading_record.save # Save the subheading

        # Now scrape the subheading URL and store the data
        scrape_and_store_subheading_data(subheading_record.url)
      end
    end
    Rails.logger.info "SyncDataJob completed"
  end

  private

  def scrape_and_store_subheading_data(url)
    scraper = CategoryScraper.new
    products = scraper.scrape_subheading_text(url) # Scrape the subheading data

    # Store the scraped data in the database
    products.each do |product_data|
      # Find or initialize the product in the database
      product = Product.find_or_initialize_by(title: product_data[:heading], company: product_data[:company_name])

      # Update the product attributes
      product.url = product_data[:href]
      product.icon = product_data[:logo]
      product.description = product_data[:details]

      # Save the product
      product.save
    end
  end
end
