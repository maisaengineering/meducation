require 'spec_helper'

describe "admin_coupons/edit" do
  before(:each) do
    @coupon = assign(:coupon, stub_model(Admin::Coupon,
      :name => "MyString",
      :discount => 1,
      :season => 1
    ))
  end

  it "renders the edit coupon form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => admin_coupons_path(@coupon), :method => "post" do
      assert_select "input#coupon_name", :name => "coupon[name]"
      assert_select "input#coupon_discount", :name => "coupon[discount]"
      assert_select "input#coupon_season", :name => "coupon[season]"
    end
  end
end
