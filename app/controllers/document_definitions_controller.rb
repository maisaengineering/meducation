class DocumentDefinitionsController < ApplicationController
  before_filter :find_organization
  before_filter :find_or_build_document_definition,except: [:create]
  layout "organization"

  def new; end

  def create
    @document_definition = DocumentDefinition.new(params[:document_definition])
    if @document_definition.save
      redirect_to org_form_and_documents_path(@organization)
    else
      render action: "new"
    end
  end

  def edit; end

  def update
    if @document_definition.update_attributes(params[:document_definition])
      redirect_to org_form_and_documents_path(@organization)
    else
      render 'edit'
    end
  end

  def update_workflow
    document_definitions = @organization.document_definitions.where(:_id.in => params[:document_definition_ids])
    document_definitions.update_all(workflow: DocumentDefinition::WORKFLOW_TYPES[:auto])
    redirect_to org_form_and_documents_path(@organization)
  end

  def destroy
    @document_definition.delete
    redirect_to org_form_and_documents_path(@organization)
  end

  #to get all the responses
  def download_responses
    tempfile,file_name = @document_definition.download_submitted_documents
    send_file tempfile.path, :type => 'application/zip',disposition: 'attachment', filename: "#{file_name}.zip"
    tempfile.close # The temp file will be deleted some time...
  end

  #----------Private Methods
  private
  def find_organization
    @organization = Organization.find(params[:organization_id])
  end

  def find_or_build_document_definition
    @document_definition =  params[:id].present? ? DocumentDefinition.find(params[:id]) :  @organization.document_definitions.build
  end

end
