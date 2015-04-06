# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :enrollment do
    family_currently_enrolled "MyString"
    active_member_of_ppc "MyString"
    age_group_and_school_days "MyString"
  end
end
