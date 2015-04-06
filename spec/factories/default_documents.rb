# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :default_document do
    document_ageRequired "MyString"
    document_intervalMax "MyString"
    document_name "MyString"
  end
end
