# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :default_immunization do
    immunization_ageRequired "MyString"
    immunization_intervalMax "MyString"
    immunization_name "MyString"
  end
end
