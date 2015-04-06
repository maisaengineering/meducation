require "spec_helper"

describe OrganizationDocumentsController do
  describe "routing" do

    it "routes to #index" do
      get("/organization_documents").should route_to("organization_documents#index")
    end

    it "routes to #new" do
      get("/organization_documents/new").should route_to("organization_documents#new")
    end

    it "routes to #show" do
      get("/organization_documents/1").should route_to("organization_documents#show", :id => "1")
    end

    it "routes to #edit" do
      get("/organization_documents/1/edit").should route_to("organization_documents#edit", :id => "1")
    end

    it "routes to #create" do
      post("/organization_documents").should route_to("organization_documents#create")
    end

    it "routes to #update" do
      put("/organization_documents/1").should route_to("organization_documents#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/organization_documents/1").should route_to("organization_documents#destroy", :id => "1")
    end

  end
end
