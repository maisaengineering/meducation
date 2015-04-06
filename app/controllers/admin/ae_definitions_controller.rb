class Admin::AeDefinitionsController < ApplicationController
  layout 'organization'
  load_and_authorize_resource class: AeDefinition
  def index
  @ae_definitions = AeDefinition.desc(:created_at)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @ae_definitions }
    end
  end

  # GET
  def show
    @ae_definition = AeDefinition.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ae_definition }
    end
  end

  # GET
  def new
    @ae_definition =  AeDefinition.new(_type: params[:type])
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @ae_definition }
    end
  end

  # GET
  def edit
    @ae_definition = AeDefinition.find(params[:id])
  end

  # POST
  def create
    @ae_definition = params[:type].eql?(AdHocAeDefinition.to_s) ? AdHocAeDefinition.create(params[:ae_definition]) :
        ScheduledAeDefinition.create(params[:ae_definition])
    if @ae_definition.save
      redirect_to admin_ae_definitions_path, notice: "'#{@ae_definition._type}' Notification was successfully created."
    else
      render action: "new"
    end
  end

# PUT
  def update
    @ae_definition = AeDefinition.find(params[:id])
    args = @ae_definition.scheduled? ? params[:scheduled_ae_definition] : params[:ad_hoc_ae_definition]
    @ae_definition.update_attributes(args || params)
    respond_to do |format|
      format.html do
        unless @ae_definition.errors.any?
          redirect_to admin_ae_definitions_url, notice: "#{@ae_definition._type} was successfully updated."
        else
          render 'edit'
        end
      end
      format.js {render nothing: true, status: @ae_definition.errors.any? ? 400 : 200}
    end
  end


  def destroy
    @ae_definition = AeDefinition.find(params[:id])
    @ae_definition.destroy
    respond_to do |format|
      format.html { redirect_to admin_ae_definitions_url }
      format.json { head :no_content }
    end
  end

end

