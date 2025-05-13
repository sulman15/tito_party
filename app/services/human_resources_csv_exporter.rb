require 'nokogiri'
require 'httparty'
require 'selenium-webdriver'
require 'csv'

class HumanResourcesCsvExporter
  # Ensure the correct driver path is set
  Selenium::WebDriver::Chrome::Service.driver_path = "/usr/local/bin/chromedriver"

  def scrape_all(url, comparison_text)
    driver = initialize_driver
    navigate_to_url(driver, url)

    # Get the page source and parse it with Nokogiri
    page_source = driver.page_source
    driver.quit

    # Parse the HTML with Nokogiri
    doc = Nokogiri::HTML(page_source)

    # Extract subcategories and their product data
    subcategories = extract_subcategories(doc, comparison_text)

    # Scrape products for each subcategory
    products_data = scrape_products_for_subcategories(subcategories)

    # Write the scraped product data to a CSV file
    write_to_csv(products_data)

    Rails.logger.info "Scraped product data saved to products_data.csv"
  end

  def scrape_subheading_text(url)
    # Initialize the Selenium WebDriver
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless') # run without opening the browser window (optional)
    options.add_argument('--no-sandbox') # prevent errors in headless mode

    # Initialize the driver with options
    driver = Selenium::WebDriver.for :chrome, options: options
    driver.navigate.to url

    # Get the page source and parse it with Nokogiri
    page_source = driver.page_source
    driver.quit

    # Parse the HTML with Nokogiri
    doc = Nokogiri::HTML(page_source)

    # Extract the desired data
    cards = doc.css('._card_j928a_9._card_1u7u9_1._cardLink_1q928_1').map do |card|
      {
        heading: card.at_css('.rt-Text.rt-r-size-4.rt-r-weight-bold.rt-truncate._cardTitle_j928a_13')&.text&.strip,
        company_name: card.at_css('.rt-Text.rt-r-size-2.rt-truncate')&.text&.strip,
        details: card.at_css('.rt-Text.rt-r-size-2._description_j928a_18')&.text&.strip,
        href: card.at_css('a')&.[]('href'), # Get the href from the anchor tag
        logo: card.at_css('.rt-AvatarImage')&.[]('src') # Get the logo src
      }
    end

    Rails.logger.info "Scraped products: #{cards.inspect}"
    cards
  end

  private

  def initialize_driver
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless') # run without opening the browser window (optional)
    options.add_argument('--no-sandbox') # prevent errors in headless mode
    Selenium::WebDriver.for :chrome, options: options
  end

  def navigate_to_url(driver, url)
    Rails.logger.info "Navigating to URL: #{url}"
    driver.manage.timeouts.page_load = 60 # Increase to 60 seconds or more as needed
    driver.navigate.to url
    Rails.logger.info "Page loaded, getting page source."
  end

  def extract_subcategories(doc, comparison_text)
    data = doc.css('.rt-reset.rt-BaseCard.rt-Card.rt-r-size-2.sm\\:rt-r-size-3.rt-variant-surface').map do |card|
      heading = card.at_css('.rt-Heading.rt-r-size-3._cardTitle_uuwu4_11')&.text&.strip
      Rails.logger.info "Heading: #{heading}"

      # Only process the card if the heading matches the comparison text
      next unless heading == comparison_text

      # Extract subheadings
      subheadings = card.css('.rt-Box._subCategories_uuwu4_16 a').map do |link|
        {
          title: link.text.strip,
          href: "https://www.vendr.com#{link['href']}"
        }
      end

      Rails.logger.info "Subheadings: #{subheadings.inspect}"
      subheadings # Return only the subheadings for this card
    end.compact.flatten # Remove nil values and flatten the array

    data
  end

  def scrape_products_for_subcategories(subcategories)
    products_data = []

    subcategories.each do |subcategory|
      products = scrape_products(subcategory[:href], subcategory[:title])
      products_data.concat(products) # Combine all products into a single array
    end

    products_data
  end

  def scrape_products(url, subcategory_title)
    driver = initialize_driver
    navigate_to_url(driver, url)

    # Set implicit wait
    driver.manage.timeouts.implicit_wait = 10 # seconds

    # Wait for the product cards to load
    wait = Selenium::WebDriver::Wait.new(timeout: 120) # seconds
    # wait.until { driver.find_element(css: '._card_j928a_9') } # Adjust th÷e selector as needed

    # Get the page source and parse it with Nokogiri
    page_source = driver.page_source
    driver.quit

    # Parse the HTML with Nokogiri
    doc = Nokogiri::HTML(page_source)

    # Extract product data using the correct CSS selectors
    products = doc.css('a._card_j928a_9._card_1u7u9_1._cardLink_1q928_1').map do |card|
      {
        title: card.at_css('.rt-Text.rt-r-size-4.rt-r-weight-bold.rt-truncate._cardTitle_j928a_13')&.text&.strip,
        price: card.at_css('.rt-Text.rt-r-size-2.rt-truncate')&.text&.strip,
        details: card.at_css('.rt-Text.rt-r-size-2._description_j928a_18')&.text&.strip,
        href: "https://www.vendr.com#{card['href']}", # Extract href directly from the anchor tag
        image: card.at_css('.rt-AvatarImage')&.[]('src'),
        subcategory: subcategory_title
      }
    end.compact # Remove nil values

    Rails.logger.info "Scraped products: #{products.inspect}"
    products
  end

  def write_to_csv(products_data)
    Rails.logger.info "Products data to write: #{products_data.inspect}"

    CSV.open("products_data.csv", "wb") do |csv|
      # Add headers
      csv << ["Product Title", "Price", "Details", "Product URL", "Image URL", "Subcategory"]
      Rails.logger.info "Writing products data to CSV #{products_data.inspect}"
      products_data.each do |product|
        csv << [
          product[:title],
          product[:price],
          product[:details],
          product[:href],
          product[:image],
          product[:subcategory] # Include the subcategory title
        ]
      end
    end
  end
end
