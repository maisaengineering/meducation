# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :member_alert do
    alert_type "MyString"
    alert_text "MyString"
    alert_subject "MyString"
  end
end
