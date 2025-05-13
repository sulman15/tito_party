class HeadingsController < ApplicationController
  def index
    @headings = Category.includes(subcategories: :products).all
  end

  def subheading_text
    url = params[:url] # Get the URL from the query parameters

    # Find the subcategory associated with the given URL
    @subcategory = Subcategory.find_by(url: url)

    # If no subcategory is found, handle that case
    if @subcategory.nil?
      flash[:alert] = "No data found for the provided URL."
      redirect_to headings_path and return
    end

    @products = @subcategory.products # Get products associated with the subcategory
    render :subheading_text # Render the view with the found products
  end
end
