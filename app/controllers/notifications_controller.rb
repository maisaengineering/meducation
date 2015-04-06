class NotificationsController < ApplicationController
  # GET /notifications
  # GET /notifications.json
  def index
    @notifications = Notification.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @notifications }
    end
  end

  # GET /notifications/1
  # GET /notifications/1.json
  def show
    @notification = Notification.find(params[:id])

    respond_to do |format|
      format.html # show.html.haml
      format.json { render json: @notification }
    end
  end

  # GET /notifications/new
  # GET /notifications/new.json
  def new

    @notification = Notification.new
    respond_to do |format|
      format.html # new.html.erbb
      format.json { render json: @notification }
    end
  end

  # GET /notifications/1/edit
  def edit
    @notification = Notification.find(params[:id])
  end

  # POST /notifications
  # POST /notifications.json
  def create
    @notification = []
    @notification = Notification.new(params[:notification])
    type = BSON::ObjectId.from_string(params[:form_need].split('_')[0])

    form_or_doc_id =  params[:form_need].split('_')[1]
    organization = Organization.find(session[:current_org])

    @organization_memberships = OrganizationMembership.where('seasons.season_year'=> "2013-2014")


    if params[:notification_type].eql?('Normal')
      if type.eql?('form')
      @notification.build_normal_notification(:description =>params[:description], :json_template_id =>form_or_doc_id )
      else
      @notification.build_normal_notification(:description =>params[:description], :doc_definition_id =>form_or_doc_id)
      end
    elsif params[:notification_type].eql?('Schedule')
      @notification.build_schedule_notification(:description =>params[:description], :date => params[:date])
    elsif params[:notification_type].eql?('AdHoc')
      @notification.build_ad_hoc_notification(:description =>params[:description], :zip =>params[:zip], :latitude =>params[:latitude], :longitude => params[:longitude])
    end
    @organization_memberships.each do |each_org_mem|
      each_org_mem.update_attributes(:notification_id => each_org_mem.notification_id + Array(@notification.id), :notification_status => "Acitve")
    end
    respond_to do |format|
      if @notification.save
        format.html { redirect_to @notification, notice: 'Notification was successfully created.' }
        format.json { render json: @notification, status: :created, location: @notification }
      else
        format.html { render action: "new" }
        format.json { render json: @notification.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /notifications/1
  # PUT /notifications/1.json
  def update
    @notification = Notification.find(params[:id])

    respond_to do |format|
      if @notification.update_attributes(params[:notification])
        format.html { redirect_to @notification, notice: 'Notification was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @notification.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notifications/1
  # DELETE /notifications/1.json
  def destroy
    @notification = Notification.find(params[:id])
    @notification.destroy

    respond_to do |format|
      format.html { redirect_to notifications_url }
      format.json { head :no_content }
    end
  end
end
