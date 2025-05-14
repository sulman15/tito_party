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

    # Extract subcategories
    subcategories = extract_subcategories(doc, comparison_text)

    # Return if no subcategories found
    return if subcategories.empty?

    # Scrape products for all subcategories
    products_data = scrape_products_for_subcategories(subcategories)

    # Write the scraped product data to a CSV file
    # write_to_csv(products_data)

    # Scrape product details from the URLs in the CSV
    product_urls = products_data.map { |product| product[:href] }
    product_details = scrape_product_details(product_urls)

    write_to_csv(product_details)
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

  def scrape_product_details(product_urls)
    product_details = []

    # Limit to the first 10 products
    product_urls.each do |url|
      driver = initialize_driver
      navigate_to_url(driver, url)

      # Set implicit wait
      driver.manage.timeouts.implicit_wait = 10 # seconds

      # Get the page source and parse it with Nokogiri
      page_source = driver.page_source
      driver.quit

      # Parse the HTML with Nokogiri
      doc = Nokogiri::HTML(page_source)

      # Extract the desired data
      detail_href = doc.at_css('.rt-Flex.rt-r-display-none.xs\\:rt-r-display-flex.rt-r-fd-row.rt-r-gap-1 a.rt-Text.rt-reset.rt-Link.rt-underline-auto')&.[]('href')

      # Extract additional details from the new class
      range_average_div = doc.at_css('.rt-Flex._rangeAverage_118fo_42')
      average_text = range_average_div&.at_css('.rt-Text.rt-r-weight-bold')&.text&.strip

      # Check if range_average_div is nil before accessing it
      if range_average_div
        additional_text = range_average_div.text.strip # Get all text within the div
      else
        Rails.logger.warn "No range average div found for URL: #{url}"
        additional_text = nil
      end

      # Extract lowest and highest values
      lowest = doc.at_css('.rt-Grid.rt-r-gtc.rt-r-ai-center.rt-r-mt._rangeSlider_118fo_13 .v-fw-600.v-fs-12')&.text&.strip
      highest = doc.at_css('.rt-Grid.rt-r-gtc.rt-r-ai-center.rt-r-mt._rangeSlider_118fo_13 ._rangeSliderLastNumber_118fo_38.v-fw-600.v-fs-12')&.text&.strip

      # Extract purchase data text
      purchase_data_text = doc.at_css('.rt-Flex.rt-r-fd-column.rt-r-gap-1._averageBuyersPay_118fo_66 .v-fs-12')&.text&.strip

      # Extract review heading
      review_heading = doc.at_css('.rt-Flex.rt-r-ai-center.rt-r-jc-space-between h2.rt-Heading.rt-r-size-6')&.text&.strip

      # Extract company size and review
      company_size_divs = doc.css('.rt-Flex.rt-r-fd-column.rt-r-ai-center.rt-r-gap-5 .rt-Flex.rt-r-fd-column.rt-r-gap-5.rt-r-w')
      company_size = company_size_divs.first&.at_css('.rt-Text.rt-r-size-1')&.text&.strip
      review = company_size_divs.first&.at_css('.rt-Text.rt-r-size-4.rt-r-weight-bold')&.text&.strip

      # Fetch all reviews from the specified class
      reviews = doc.css('.rt-Flex.rt-r-fd-column.rt-r-gap-5.rt-r-w .rt-Text.rt-r-size-4.rt-r-weight-bold').map do |review_span|
        review_span.text.strip
      end

      # Store the details in a hash
      product_details << {
        detail_href: detail_href ? "#{detail_href}" : nil, # Concatenate the base URL with the href
        average_text: average_text, # Extracted text from the span
        additional_text: additional_text, # Additional text from the div
        lowest: lowest, # Lowest value
        highest: highest, # Highest value
        purchase_data_text: purchase_data_text, # New purchase data text
        review_heading: review_heading, # New review heading
        company_size: company_size, # New company size
        # review: review, # New review
        reviews: reviews # Store all reviews as an array
      }
    end

    Rails.logger.info "Scraped product details: #{product_details.inspect}"
    product_details
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
      # Scrape products for each subcategory
      products = scrape_products(subcategory[:href], subcategory[:title])
      products_data.concat(products) # Collect all products
    end

    products_data
  end

  def scrape_products(url, subcategory_title)
    driver = initialize_driver
    navigate_to_url(driver, url)

    # Set implicit wait
    driver.manage.timeouts.implicit_wait = 10 # seconds

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

  # def write_to_csv(products_data)
  #   Rails.logger.info "Products data to write: #{products_data.inspect}"

  #   CSV.open("products_data.csv", "wb") do |csv|
  #     # Add headers
  #     csv << ["Product Title", "Price", "Details", "Product URL", "Image URL", "Subcategory"]
  #     Rails.logger.info "Writing products data to CSV #{products_data.inspect}"
  #     products_data.each do |product|
  #       csv << [
  #         product[:title],
  #         product[:price],
  #         product[:details],
  #         product[:href],
  #         product[:image],
  #         product[:subcategory] # Include the subcategory title
  #       ]
  #     end
  #   end
  # end

  def write_to_csv(product_details)
    Rails.logger.info "Product details to write: #{product_details.inspect}"

    CSV.open("product_details.csv", "wb") do |csv|
      # Add headers
      csv << ["Detail URL", "Average Text", "Additional Text", "Lowest", "Highest", "Purchase Data Text", "Review Heading", "Company Size", "All Reviews"]

      product_details.each do |product|
        csv << [
          product[:detail_href],
          product[:average_text],
          product[:additional_text],
          product[:lowest],
          product[:highest],
          product[:purchase_data_text],
          product[:review_heading],
          product[:company_size],
          product[:reviews].join(", ")
        ]
      end
    end
  end
  
end
