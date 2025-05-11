require 'nokogiri'
require 'httparty'
require 'selenium-webdriver'

class WebsiteScraper
  include SeleniumHelper

  def initialize(website)
    @website = website
    @driver = setup_selenium
  end

  def scrape
    @driver.get(@website.url)
    # Perform scraping actions here
    # Example: Extracting the page title
    title = @driver.title
    # Store the scraped data or perform further processing
    puts "Scraped Title: #{title}"
  ensure
    @driver.quit
  end

  def scrape_website(url)
    search_term = PurchaseRequest.last&.description
    return nil unless search_term.present?

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')

    driver = Selenium::WebDriver.for(:chrome, options: options)
    
    begin
      Rails.logger.info "Starting to navigate to URL: #{url}"
      driver.navigate.to url
      
      # Wait for a specific element to be present, indicating the page has loaded
      wait = Selenium::WebDriver::Wait.new(timeout: 20)
      wait.until { driver.find_element(:css, '#nav-search') }
      
      # Then find the search input field
      search_input = wait.until { driver.find_element(:id, 'twotabsearchtextbox') }
      
      # Type the search term from Purchase_request
      search_input.clear
      search_input.send_keys(search_term)
      Rails.logger.info "Searching for term: #{search_term}"
      
      # Wait for 8 seconds after typing
      sleep(8)
      
      # Find and click the search button
      search_button = driver.find_element(:id, 'nav-search-submit-button')
      search_button.click
      
      # Wait another 8 seconds for results to load
      sleep(8)
      
      # Wait for a specific element that indicates the search results have loaded
      wait = Selenium::WebDriver::Wait.new(timeout: 20)
      wait.until { driver.find_element(:css, '.s-result-list') }
      
      # Then find the search results container
      search_results = driver.find_element(:css, '.s-search-results')
      
      # Extract product information from each search result item
      products = []
      search_results.find_elements(:css, '.s-result-item').each do |item|
        product = {}
        
        # Extract product image URL
        image_element = item.find_element(:css, '.s-product-image img')
        product[:image_url] = image_element.attribute('src')
        
        # Extract product title and URL
        title_element = item.find_element(:css, '.s-product-title a')
        product[:title] = title_element.text
        product[:url] = title_element.attribute('href')
        
        # Extract product price
        price_element = item.find_element(:css, '.s-product-price .a-price-whole')
        product[:price] = price_element.text
        
        # Extract product rating
        rating_element = item.find_element(:css, '.s-product-rating .a-icon-alt')
        product[:rating] = rating_element.text
        
        products << product
      end
      
      Rails.logger.info "Extracted #{products.length} products"
      
      if products.empty?
        Rails.logger.error "No products were found"
        return nil
      end
      
      # Check the current URL after navigation
      current_url = driver.current_url
      Rails.logger.info "Current URL: #{current_url}"
      
      # Inspect the page source
      page_source = driver.page_source
      Rails.logger.info "Page Source: #{page_source}"
      
      # Return the extracted products and the search term used
      { products: products, search_term: search_term }
    rescue Selenium::WebDriver::Error::NoSuchElementError => e
      Rails.logger.error "Search results container not found: #{e.message}"
      return nil
    rescue Selenium::WebDriver::Error::TimeoutError => e
      Rails.logger.error "Timed out waiting for search input field: #{e.message}"
      return nil
    ensure
      driver.quit
    end
  end
end