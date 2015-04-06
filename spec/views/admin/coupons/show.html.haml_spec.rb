require 'spec_helper'

describe "admin_coupons/show" do
  before(:each) do
    @coupon = assign(:coupon, stub_model(Admin::Coupon,
      :name => "Name",
      :discount => 1,
      :season => 2
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/1/)
    rendered.should match(/2/)
  end
end
