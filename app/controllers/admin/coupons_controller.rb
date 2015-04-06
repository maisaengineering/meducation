class Admin::CouponsController < ApplicationController
  load_and_authorize_resource class: Admin::Coupon
  # GET /admin/coupons
  #skip_before_filter :authenticate_user!
  # GET /admin/coupons.json
 layout "organization"
 
  def index
    @admin_coupons = Admin::Coupon.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @admin_coupons }
    end
  end

  # GET /admin/coupons/1
  # GET /admin/coupons/1.json
  def show
    @admin_coupon = Admin::Coupon.find(params[:id])

    respond_to do |format|
      format.html # show.html.haml
      format.json { render json: @admin_coupon }
    end
  end

  # GET /admin/coupons/new
  # GET /admin/coupons/new.json
  def new
    @admin_coupon = Admin::Coupon.new
    
    respond_to do |format|
      format.html # new.html.erbb
      format.json { render json: @admin_coupon }
    end
  end

  # GET /admin/coupons/1/edit
  def edit
    @admin_coupon = Admin::Coupon.find(params[:id])
  end

  # POST /admin/coupons
  # POST /admin/coupons.json
  def create
    if (params[:admin_coupon] && params[:admin_coupon][:discount].blank?)
      params[:admin_coupon][:discount] = 100
    end

    @admin_coupon = Admin::Coupon.new(params[:admin_coupon])

    respond_to do |format|
      if @admin_coupon.save
        format.html { redirect_to @admin_coupon, notice: 'Coupon was successfully created.' }
        format.json { render json: @admin_coupon, status: :created, location: @admin_coupon }
      else
        format.html { render action: "new" }
        format.json { render json: @admin_coupon.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /admin/coupons/1
  # PUT /admin/coupons/1.json
  def update
    @admin_coupon = Admin::Coupon.find(params[:id])

    respond_to do |format|
      if @admin_coupon.update_attributes(params[:admin_coupon])
        format.html { redirect_to @admin_coupon, notice: 'Coupon was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @admin_coupon.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/coupons/1
  # DELETE /admin/coupons/1.json
  def destroy
    @admin_coupon = Admin::Coupon.find(params[:id])
    @admin_coupon.destroy

    respond_to do |format|
      format.html { redirect_to admin_coupons_url }
      format.json { head :no_content }
    end
  end
end
