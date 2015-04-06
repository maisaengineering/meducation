# Read about factories at https://github.com/thoughtbot/factory_girl

#FactoryGirl.define :user do |f|
#  f.sequence(:email) { |n| "test#{n}@gmail.com"}
#  f.fname "fist_name"
#  f.password "aaaa1234"
#  f.password_confirmation "aaaa1234"
#end

FactoryGirl.define do
  factory :user do
    session_name "MyString"
    sequence(:email) { |n| "test#{n}@gmail.com"}
    fname "fist_name"
    password "aaaa1234"
    password_confirmation "aaaa1234"
  end
end
