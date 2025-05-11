class HeadingsController < ApplicationController
  def index
    @headings = Heading.includes(:subheadings).all
  end

  def subheading_text
    url = params[:url] # Get the URL from the query parameters
    scraper = CategoryScraper.new

    # Check if cards already exist for the given URL
    @cards = Card.where(href: url)

    if @cards.empty?
      @cards = scraper.scrape_subheading_text(url) # Call the method to scrape and store data
    end

    render :subheading_text # Render the new view
  end
end
