# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :transaction do
    transaction_id "MyString"
    type ""
    amount "MyString"
    status ""
    fname "MyString"
    lname "MyString"
    email "MyString"
  end
end
