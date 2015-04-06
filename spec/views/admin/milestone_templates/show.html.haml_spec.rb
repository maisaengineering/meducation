require 'spec_helper'

describe "admin_milestone_templates/show.html.haml" do
  before(:each) do
    @milestone_template = assign(:milestone_template, stub_model(Admin::MilestoneTemplate,
      :name => "Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
  end
end
