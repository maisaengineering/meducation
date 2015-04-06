# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :default_med_test do
    medTest_ageRequired "MyString"
    medTest_intervalMax "MyString"
    medTest_name "MyString"
  end
end
