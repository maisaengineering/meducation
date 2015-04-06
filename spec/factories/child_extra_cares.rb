# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :child_extra_care do
    food_allergies "MyString"
    medical_issues "MyString"
    special_needs "MyString"
    other_concerns "MyString"
  end
end
