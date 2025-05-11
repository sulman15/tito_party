require 'nokogiri'
require 'httparty'
require 'selenium-webdriver'

class CategoryScraper
  # Ensure the correct driver path is set
  Selenium::WebDriver::Chrome::Service.driver_path = "/usr/local/bin/chromedriver"

  def scrape(url)
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

    # Extract data from the specified structure
    data = doc.css('.rt-reset.rt-BaseCard.rt-Card.rt-r-size-2.sm\\:rt-r-size-3.rt-variant-surface').map do |card|
      heading = card.at_css('.rt-Heading.rt-r-size-3._cardTitle_uuwu4_11')&.text&.strip
      subheadings = card.css('.rt-Box._subCategories_uuwu4_16 .rt-Box.rt-r-pb-2 a').map do |link|
        {
          title: link.text.strip,
          href: "https://www.vendr.com#{link['href']}"
        }
      end

      {
        title: heading,
        subheadings: subheadings
      }
    end

    # Return the extracted data
    data
  end
end
