require 'spec_helper'

describe "milestones/show.html.haml" do
  before(:each) do
    @milestone = assign(:milestone, stub_model(Milestone,
      :additional_text => "Additional Text"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Additional Text/)
  end
end
