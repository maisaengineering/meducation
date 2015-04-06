# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :required_document do
    document_intervalMax "MyString"
    document_ageRequired "MyString"
    document_name "MyString"
  end
end
