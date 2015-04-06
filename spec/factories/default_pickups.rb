# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :default_pickup do
    pickup_id 1
    pickup_relationship "MyString"
    pickup_notes "MyString"
  end
end
