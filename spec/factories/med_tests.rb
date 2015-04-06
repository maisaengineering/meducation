# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :med_test do
    medTest_name "MyString"
    medTest_date ""
    medTest_interval "MyString"
    medTest_approvalStatus "MyString"
    medTest_documentPdfId "MyString"
    medTest_notes "MyString"
  end
end
