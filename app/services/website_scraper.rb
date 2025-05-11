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
    title = @driver.title
    puts "Scraped Title: #{title}"
  ensure
    @driver.quit
  end

  def scrape_website(url)
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')

    driver = Selenium::WebDriver.for(:chrome, options: options)
    
    begin
      driver.navigate.to url
      wait = Selenium::WebDriver::Wait.new(timeout: 10)
      wait.until { driver.find_element(:css, 'h1') } # Wait for the main heading to load

      # Get the body content after the page loads
      body_element = driver.find_element(:tag_name, 'body')
      body_html = body_element.attribute('innerHTML')

      # Parse the HTML using Nokogiri
      doc = Nokogiri::HTML(body_html)

      # Extract categories and their descriptions
      categories = []
      doc.css('.category-item').each do |category|
        category_name = category.at_css('h2')&.text
        category_description = category.at_css('p')&.text
        categories << { name: category_name, description: category_description }
      end

      Rails.logger.info "Extracted #{categories.length} categories"

      # Return the extracted categories
      { categories: categories }
    rescue StandardError => e
      Rails.logger.error "Website scraping error: #{e.message}"
      nil
    ensure
      driver.quit
    end
  end
end

scraper = WebsiteScraper.new(your_website_object)
data = scraper.scrape_website('https://www.vendr.com/categories')
puts data