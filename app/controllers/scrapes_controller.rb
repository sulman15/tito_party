# app/controllers/scrapes_controller.rb
class ScrapesController < ApplicationController
    def index
      @data = CategoryScraper.new.scrape('https://www.vendr.com/categories') # Replace with your URL
    end
  end