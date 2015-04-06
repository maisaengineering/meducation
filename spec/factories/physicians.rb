# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :physician do
    physician_name ""
    physician_title "MyString"
    physician_type "MyString"
    physician_phone "MyString"
    physician_address1 "MyString"
    physician_address2 "MyString"
    physician_address3 "MyString"
    physician_address4 "MyString"
    physician_city "MyString"
    physician_state "MyString"
    physician_zip "MyString"
    physician_country "MyString"
    physician_email "MyString"
    physician_notes "MyString"
  end
end
