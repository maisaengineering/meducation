  class CategoriesController < ApplicationController
  before_filter :find_current_user_profile, only: [:ancestors, :edit_category_children]
  skip_before_filter :authenticate_user!
  def index
    @parent_one = Category.where(:name => params[:position]).first
    #child_one = Category.where({'_id' => { "$in" => @parent_one.child_ids}}).first   if @parent_one.child_ids.present?
    #child_two = Category.where({'_id' => { "$in" => child_one.child_ids}}).first if child_one.child_ids.present?
  end

  def get_child
    @category_all = []
    parent_one = Category.where(:name => params[:position]).first
    parent_one.children.each do |category|
      @category_all << category.name
    end
    #  cat_gory = Category.decorate_parent_hash(category_all)
    render json: @category_all
  end

  def ancestors
    @category = Category.find(params[:id]) rescue nil
    @children = @category.children  if @category
    render layout: false
  end

  def edit_category_children
    @category = Category.find(params[:id]) rescue nil
    @children = @category.children  if @category
    render layout: false
  end

end
