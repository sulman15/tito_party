class CategoriesController < ApplicationController
  def index
    @categories = Category.includes(subcategories: :products).all
  end

  def show
    @category = Category.find(params[:id])
    @subcategories = @category.subcategories.includes(:products)
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to @category, notice: 'Category was successfully created.'
    else
      render :new
    end
  end

  private

  def category_params
    params.require(:category).permit(:title, :url, :description)
  end
end
