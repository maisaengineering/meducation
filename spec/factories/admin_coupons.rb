# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :admin_coupon, :class => 'Admin::Coupon' do
    name "MyString"
    discount 1
    season 1
  end
end
