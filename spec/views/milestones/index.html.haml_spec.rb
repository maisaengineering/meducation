require 'spec_helper'

describe "milestones/index.html.haml" do
  before(:each) do
    assign(:milestones, [
      stub_model(Milestone,
        :additional_text => "Additional Text"
      ),
      stub_model(Milestone,
        :additional_text => "Additional Text"
      )
    ])
  end

  it "renders a list of milestones" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Additional Text".to_s, :count => 2
  end
end
