require 'spec_helper'

describe "organization_documents/edit" do
  before(:each) do
    @organization_document = assign(:organization_document, stub_model(OrganizationDocument,
      :doc => "MyString",
      :doc_id => "MyString",
      :doc_type => "MyString"
    ))
  end

  it "renders the edit organization_document form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => organization_documents_path(@organization_document), :method => "post" do
      assert_select "input#organization_document_doc", :name => "organization_document[doc]"
      assert_select "input#organization_document_doc_id", :name => "organization_document[doc_id]"
      assert_select "input#organization_document_doc_type", :name => "organization_document[doc_type]"
    end
  end
end
