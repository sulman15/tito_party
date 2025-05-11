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

    cards
  end
end
