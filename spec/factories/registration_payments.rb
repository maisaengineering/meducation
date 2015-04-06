# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :registration_payment do
    payment_date "MyString"
    payment_nextDue "MyString"
    payment_amount "MyString"
    payment_couponCode "MyString"
    payment_couponAmount "MyString"
    payment_madeById "MyString"
    paymentCcNum "MyString"
    paymentCcExp "MyString"
    paymentAuthCode "MyString"
  end
end
