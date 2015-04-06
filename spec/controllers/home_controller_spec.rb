require 'spec_helper'

describe HomeController do
  
  def valid_attributes
    {:networkId => 'KL-NWK-1', :status => 'active', :name => 'Peachtree Presbyterian Preschool',
      :food_allergies => '', :medical_issues => '', :special_needs => '', :other_concerns => '',
      :enrollments => [Enrollment.new(:family_currently_enrolled => '', :active_member_of_ppc => '', :age_group_and_school_days => '')],  
      :required_immunizations => [RequiredImmunization.new(:immunization_name => '', :immunization_intervalMax =>'0',
      :immunization_ageRequired=>'')],
      :administrators => [Administrator.new(:administrator_id => '1', :administrator_name => "Josan Gane")],
      :required_med_tests => [RequiredMedTest.new(:medTest_name => '', :medTest_ageRequired => '', 
      :medTest_intervalMax=> '')],
      :linked_orgs => [LinkedOrg.new(:linkedOrg_name => '', :linkedOrg_id => '')],
      :required_documents => [RequiredDocument.new(:document_intervalMax => '', 
      :document_ageRequired => '', :document_name=> '')]}
  end
  
  describe "GET 'index'" do        
    it "should assigns organizaton details at @organizations" do
      organization = Organization.create! valid_attributes      
      get 'index', {:id => to_param}
      assigns(:organization).should eq(organization)
    end
    
  end

end
