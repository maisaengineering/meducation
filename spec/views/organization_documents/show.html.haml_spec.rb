require 'spec_helper'

describe "organization_documents/show" do
  before(:each) do
    @organization_document = assign(:organization_document, stub_model(OrganizationDocument,
      :doc => "Doc",
      :doc_id => "Doc",
      :doc_type => "Doc Type"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Doc/)
    rendered.should match(/Doc/)
    rendered.should match(/Doc Type/)
  end
end
