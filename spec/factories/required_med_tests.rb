# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :required_med_test do
    medTest_ageRequired "MyString"
    medTest_name "MyString"
    medTest_intervalMax "MyString"
  end
end
