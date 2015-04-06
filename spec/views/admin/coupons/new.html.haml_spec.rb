require 'spec_helper'

describe "admin_coupons/new" do
  before(:each) do
    assign(:coupon, stub_model(Admin::Coupon,
      :name => "MyString",
      :discount => 1,
      :season => 1
    ).as_new_record)
  end

  it "renders new coupon form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => admin_coupons_path, :method => "post" do
      assert_select "input#coupon_name", :name => "coupon[name]"
      assert_select "input#coupon_discount", :name => "coupon[discount]"
      assert_select "input#coupon_season", :name => "coupon[season]"
    end
  end
end
