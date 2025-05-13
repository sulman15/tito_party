class SubcategoriesController < ApplicationController
  def index
    @subcategories = Subcategory.includes(:products).all
  end

  def show
    @subcategory = Subcategory.find(params[:id])
    @products = @subcategory.products
  end

  def create
    @subcategory = Subcategory.new(subcategory_params)
    if @subcategory.save
      redirect_to @subcategory, notice: 'Subcategory was successfully created.'
    else
      render :new
    end
  end

  private

  def subcategory_params
    params.require(:subcategory).permit(:title, :url, :category_id)
  end
end
