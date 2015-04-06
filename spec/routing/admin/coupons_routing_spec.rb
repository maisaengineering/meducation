require "spec_helper"

describe Admin::CouponsController do
  describe "routing" do

    it "routes to #index" do
      get("/admin_coupons").should route_to("admin_coupons#index")
    end

    it "routes to #new" do
      get("/admin_coupons/new").should route_to("admin_coupons#new")
    end

    it "routes to #show" do
      get("/admin_coupons/1").should route_to("admin_coupons#show", :id => "1")
    end

    it "routes to #edit" do
      get("/admin_coupons/1/edit").should route_to("admin_coupons#edit", :id => "1")
    end

    it "routes to #create" do
      post("/admin_coupons").should route_to("admin_coupons#create")
    end

    it "routes to #update" do
      put("/admin_coupons/1").should route_to("admin_coupons#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/admin_coupons/1").should route_to("admin_coupons#destroy", :id => "1")
    end

  end
end
