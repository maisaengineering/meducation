require "spec_helper"

describe M::ProfilesController do
  describe "routing" do

    it "routes to #index" do
      get("/m/profiles").should route_to("m/profiles#index")
    end

    it "routes to #new" do
      get("/m/profiles/new").should route_to("m/profiles#new")
    end

    it "routes to #show" do
      get("/m/profiles/1").should route_to("m/profiles#show", :id => "1")
    end

    it "routes to #edit" do
      get("/m/profiles/1/edit").should route_to("m/profiles#edit", :id => "1")
    end

    it "routes to #create" do
      post("/m/profiles").should route_to("m/profiles#create")
    end

    it "routes to #update" do
      put("/m/profiles/1").should route_to("m/profiles#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/m/profiles/1").should route_to("m/profiles#destroy", :id => "1")
    end

  end
end
