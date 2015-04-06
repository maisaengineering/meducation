# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :measurement do
    measurement_name "MyString"
    measurement_unit ""
    measurement_data "MyString"
  end
end
