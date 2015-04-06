# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :required_immunization do
    immunization_intervalMax "MyString"
    immunization_name "MyString"
    immunization_ageRequired "MyString"
  end
end
