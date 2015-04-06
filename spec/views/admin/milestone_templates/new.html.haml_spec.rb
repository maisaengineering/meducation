require 'spec_helper'

describe "admin_milestone_templates/new.html.haml" do
  before(:each) do
    assign(:milestone_template, stub_model(Admin::MilestoneTemplate,
      :name => "MyString"
    ).as_new_record)
  end

  it "renders new milestone_template form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => admin_milestone_templates_path, :method => "post" do
      assert_select "input#milestone_template_name", :name => "milestone_template[name]"
    end
  end
end
