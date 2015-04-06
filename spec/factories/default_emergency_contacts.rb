# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :default_emergency_contact do
    emergencyContacts_id 1
    emergencyContacts_relationship "MyString"
    emergencyContacts_notes "MyString"
  end
end
