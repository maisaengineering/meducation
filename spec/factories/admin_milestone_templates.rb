# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :admin_milestone_template, :class => 'Admin::MilestoneTemplate' do
    name "MyString"
  end
end
