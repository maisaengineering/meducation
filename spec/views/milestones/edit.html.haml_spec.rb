require 'spec_helper'

describe "milestones/edit.html.haml" do
  before(:each) do
    @milestone = assign(:milestone, stub_model(Milestone,
      :additional_text => "MyString"
    ))
  end

  it "renders the edit milestone form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => milestones_path(@milestone), :method => "post" do
      assert_select "input#milestone_additional_text", :name => "milestone[additional_text]"
    end
  end
end
