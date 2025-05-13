class HomeController < ApplicationController
  def index
  end

  def sync
    SyncDataJob.perform_later # Enqueue the job to run in the background
    redirect_to root_path, notice: 'Sync process started!'
  end

  def scrape_categories
    scraper = CategoryScraper.new
    categories_data = scraper.scrape('https://www.vendr.com/categories') # Replace with your URL

    categories_data.each do |category_data|
      category = Category.find_or_initialize_by(title: category_data[:title])
      category.url = category_data[:url]
      category.description = category_data[:description]
      category.save

      category_data[:subheadings].each do |subheading|
        subcategory = category.subcategories.find_or_initialize_by(title: subheading[:title])
        subcategory.url = subheading[:href]
        subcategory.save
      end
    end

    redirect_to root_path, notice: 'Categories and subcategories have been scraped and saved!'
  end

  def scrape_products
    # Assuming you want to scrape products for all subcategories
    Subcategory.find_each do |subcategory|
      scraper = CategoryScraper.new
      products_data = scraper.scrape_subheading_text(subcategory.url)

      products_data.each do |product_data|
        product = subcategory.products.find_or_initialize_by(title: product_data[:heading])
        product.url = product_data[:href]
        product.icon = product_data[:logo]
        product.company = product_data[:company_name]
        product.description = product_data[:details]
        product.save
      end
    end

    redirect_to root_path, notice: 'Products have been scraped and saved!'
  end

  def export_csv
    csv_data = CsvExporter.export_categories_with_subcategories_and_products
    send_data csv_data, filename: "categories_subcategories_products.csv"
  end

  def export_human_resources_csv
  #   csv_data = HumanResourcesCsvExporter.export_human_resources_data

  #   if csv_data
  #     send_data csv_data, filename: "human_resources_data.csv"
  #   else
  #     redirect_to root_path, alert: 'Human Resources category not found.'
  #   end
  end

  def scrape_human_resources
    exporter = HumanResourcesCsvExporter.new
    url = "https://www.vendr.com/categories" # Replace with the actual URL
    comparison_text = "Human Resources" # Replace with the actual comparison text

    # Call the scrape_all method to perform the scraping
    exporter.scrape_all(url, comparison_text)

    # Check if the CSV file was created successfully
    csv_file_path = "products_data.csv"
    if File.exist?(csv_file_path)
      send_file csv_file_path, type: 'text/csv', disposition: 'attachment'
    else
      flash[:alert] = "Failed to create CSV file."
      redirect_to root_path
    end
  end

  private

  def scrape_and_store_subheading_data(url)
    scraper = CategoryScraper.new
    cards = scraper.scrape_subheading_text(url) # Scrape the subheading data

    # Store the scraped data in the database
    cards.each do |card_data|
      # Find or initialize the card in the database
      card = Card.find_or_initialize_by(heading: card_data[:heading], company_name: card_data[:company_name])

      # Update the card attributes
      card.details = card_data[:details]
      card.href = card_data[:href]
      card.logo = card_data[:logo]

      # Save the card
      card.save
    end
  end
end
