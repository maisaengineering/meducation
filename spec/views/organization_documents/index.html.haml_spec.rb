require 'spec_helper'

describe "organization_documents/index" do
  before(:each) do
    assign(:organization_documents, [
      stub_model(OrganizationDocument,
        :doc => "Doc",
        :doc_id => "Doc",
        :doc_type => "Doc Type"
      ),
      stub_model(OrganizationDocument,
        :doc => "Doc",
        :doc_id => "Doc",
        :doc_type => "Doc Type"
      )
    ])
  end

  it "renders a list of organization_documents" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Doc".to_s, :count => 2
    assert_select "tr>td", :text => "Doc".to_s, :count => 2
    assert_select "tr>td", :text => "Doc Type".to_s, :count => 2
  end
end
