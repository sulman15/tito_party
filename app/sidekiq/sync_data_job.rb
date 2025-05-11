class SyncDataJob < ApplicationJob
  queue_as :default

  def perform
    scraper = CategoryScraper.new

    # Call the scrape method to get all data
    data = scraper.scrape('https://www.vendr.com/categories') # Replace with the actual URL

    # Store or update the data in the database
    data.each do |category|
      heading = Heading.find_or_initialize_by(title: category[:title]) # Find or initialize heading
      heading.save # Save the heading

      category[:subheadings].each do |subheading|
        # Find or initialize subheading
        subheading_record = heading.subheadings.find_or_initialize_by(title: subheading[:title])
        subheading_record.href = subheading[:href] # Update href
        subheading_record.save # Save the subheading

        # Now scrape the subheading URL and store the data
        scrape_and_store_subheading_data(subheading_record.href)
      end
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
