class HomeController < ApplicationController
  def index
  end

  def sync
    SyncDataJob.perform_later # Enqueue the job to run in the background
    redirect_to root_path, notice: 'Sync process started!'
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
