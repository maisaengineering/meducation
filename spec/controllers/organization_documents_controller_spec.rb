require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe OrganizationDocumentsController do

  # This should return the minimal set of attributes required to create a valid
  # OrganizationDocument. As you add validations to OrganizationDocument, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {}
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # OrganizationDocumentsController. Be sure to keep this updated too.
  def valid_session
    {}
  end

  describe "GET index" do
    it "assigns all organization_documents as @organization_documents" do
      organization_document = OrganizationDocument.create! valid_attributes
      get :index, {}, valid_session
      assigns(:organization_documents).should eq([organization_document])
    end
  end

  describe "GET show" do
    it "assigns the requested organization_document as @organization_document" do
      organization_document = OrganizationDocument.create! valid_attributes
      get :show, {:id => organization_document.to_param}, valid_session
      assigns(:organization_document).should eq(organization_document)
    end
  end

  describe "GET new" do
    it "assigns a new organization_document as @organization_document" do
      get :new, {}, valid_session
      assigns(:organization_document).should be_a_new(OrganizationDocument)
    end
  end

  describe "GET edit" do
    it "assigns the requested organization_document as @organization_document" do
      organization_document = OrganizationDocument.create! valid_attributes
      get :edit, {:id => organization_document.to_param}, valid_session
      assigns(:organization_document).should eq(organization_document)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new OrganizationDocument" do
        expect {
          post :create, {:organization_document => valid_attributes}, valid_session
        }.to change(OrganizationDocument, :count).by(1)
      end

      it "assigns a newly created organization_document as @organization_document" do
        post :create, {:organization_document => valid_attributes}, valid_session
        assigns(:organization_document).should be_a(OrganizationDocument)
        assigns(:organization_document).should be_persisted
      end

      it "redirects to the created organization_document" do
        post :create, {:organization_document => valid_attributes}, valid_session
        response.should redirect_to(OrganizationDocument.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved organization_document as @organization_document" do
        # Trigger the behavior that occurs when invalid params are submitted
        OrganizationDocument.any_instance.stub(:save).and_return(false)
        post :create, {:organization_document => {}}, valid_session
        assigns(:organization_document).should be_a_new(OrganizationDocument)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        OrganizationDocument.any_instance.stub(:save).and_return(false)
        post :create, {:organization_document => {}}, valid_session
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested organization_document" do
        organization_document = OrganizationDocument.create! valid_attributes
        # Assuming there are no other organization_documents in the database, this
        # specifies that the OrganizationDocument created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        OrganizationDocument.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => organization_document.to_param, :organization_document => {'these' => 'params'}}, valid_session
      end

      it "assigns the requested organization_document as @organization_document" do
        organization_document = OrganizationDocument.create! valid_attributes
        put :update, {:id => organization_document.to_param, :organization_document => valid_attributes}, valid_session
        assigns(:organization_document).should eq(organization_document)
      end

      it "redirects to the organization_document" do
        organization_document = OrganizationDocument.create! valid_attributes
        put :update, {:id => organization_document.to_param, :organization_document => valid_attributes}, valid_session
        response.should redirect_to(organization_document)
      end
    end

    describe "with invalid params" do
      it "assigns the organization_document as @organization_document" do
        organization_document = OrganizationDocument.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        OrganizationDocument.any_instance.stub(:save).and_return(false)
        put :update, {:id => organization_document.to_param, :organization_document => {}}, valid_session
        assigns(:organization_document).should eq(organization_document)
      end

      it "re-renders the 'edit' template" do
        organization_document = OrganizationDocument.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        OrganizationDocument.any_instance.stub(:save).and_return(false)
        put :update, {:id => organization_document.to_param, :organization_document => {}}, valid_session
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested organization_document" do
      organization_document = OrganizationDocument.create! valid_attributes
      expect {
        delete :destroy, {:id => organization_document.to_param}, valid_session
      }.to change(OrganizationDocument, :count).by(-1)
    end

    it "redirects to the organization_documents list" do
      organization_document = OrganizationDocument.create! valid_attributes
      delete :destroy, {:id => organization_document.to_param}, valid_session
      response.should redirect_to(organization_documents_url)
    end
  end

end
