require 'spec_helper'

describe "admin_milestone_templates/edit.html.haml" do
  before(:each) do
    @milestone_template = assign(:milestone_template, stub_model(Admin::MilestoneTemplate,
      :name => "MyString"
    ))
  end

  it "renders the edit milestone_template form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => admin_milestone_templates_path(@milestone_template), :method => "post" do
      assert_select "input#milestone_template_name", :name => "milestone_template[name]"
    end
  end
end
