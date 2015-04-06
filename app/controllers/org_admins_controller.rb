class OrgAdminsController < ApplicationController
  before_filter :find_organization
  load_and_authorize_resource class: Organization

  def index
    @admins = @organization.admins
  end

  def new
    @user = User.new
  end


  def create
    @user = User.where(email: params[:user][:email]).first if params[:user][:email].present?
    if @user
      @user.create_role(:org_admin,[@organization.id])
      redirect_to org_admins_path(@organization),notice: "Admin role Assigned to already existing user"
    else
      @user = User.new(params[:user])
      #@user.password = @user.password_confirmation = '123456'
      if @user.save
        @user.create_role(:org_admin,[@organization.id])
        redirect_to org_admins_path(@organization),notice: "User created newly and assigned the admin role"
      else
        render 'new'
      end
    end
  end

  private
  def find_organization
    @organization = Organization.find(params[:id])
  end

end
