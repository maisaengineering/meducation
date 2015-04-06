# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :parent_id do
    parent_id 1
    parent_relationship ""
    parent_notes "MyString"
  end
end
