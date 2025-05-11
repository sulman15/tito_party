class HeadingsController < ApplicationController
  def index
    @headings = Heading.includes(:subheadings).all
  end
end
