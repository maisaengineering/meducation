require 'spec_helper'

describe "admin_coupons/index" do
  before(:each) do
    assign(:admin_coupons, [
      stub_model(Admin::Coupon,
        :name => "Name",
        :discount => 1,
        :season => 2
      ),
      stub_model(Admin::Coupon,
        :name => "Name",
        :discount => 1,
        :season => 2
      )
    ])
  end

  it "renders a list of admin_coupons" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
  end
end
