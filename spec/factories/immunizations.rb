# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :immunization do
    immunization_name "MyString"
    immunization_date "MyString"
    immunization_interval "MyString"
    immunization_approval_status "MyString"
    immunization_documentPdfId ""
    immunization_notes "MyString"
  end
end
