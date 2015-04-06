require "spec_helper"

describe Admin::MilestoneTemplatesController do
  describe "routing" do

    it "routes to #index" do
      get("/admin_milestone_templates").should route_to("admin_milestone_templates#index")
    end

    it "routes to #new" do
      get("/admin_milestone_templates/new").should route_to("admin_milestone_templates#new")
    end

    it "routes to #show" do
      get("/admin_milestone_templates/1").should route_to("admin_milestone_templates#show", :id => "1")
    end

    it "routes to #edit" do
      get("/admin_milestone_templates/1/edit").should route_to("admin_milestone_templates#edit", :id => "1")
    end

    it "routes to #create" do
      post("/admin_milestone_templates").should route_to("admin_milestone_templates#create")
    end

    it "routes to #update" do
      put("/admin_milestone_templates/1").should route_to("admin_milestone_templates#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/admin_milestone_templates/1").should route_to("admin_milestone_templates#destroy", :id => "1")
    end

  end
end
