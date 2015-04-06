require 'spec_helper'

describe "admin_milestone_templates/index.html.haml" do
  before(:each) do
    assign(:admin_milestone_templates, [
      stub_model(Admin::MilestoneTemplate,
        :name => "Name"
      ),
      stub_model(Admin::MilestoneTemplate,
        :name => "Name"
      )
    ])
  end

  it "renders a list of admin_milestone_templates" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
  end
end
