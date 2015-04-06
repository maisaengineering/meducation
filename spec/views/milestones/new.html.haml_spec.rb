require 'spec_helper'

describe "milestones/new.html.haml" do
  before(:each) do
    assign(:milestone, stub_model(Milestone,
      :additional_text => "MyString"
    ).as_new_record)
  end

  it "renders new milestone form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => milestones_path, :method => "post" do
      assert_select "input#milestone_additional_text", :name => "milestone[additional_text]"
    end
  end
end
