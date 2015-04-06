require 'spec_helper'

describe Profile do
  
  def valid_profile_data
    @user = FactoryGirl.create(:user)
    {:fname => "test_first_name", :lname => "test_last_name", :birthdate => "10/04/1989"}
  end
  
  describe "Associations" do
    it "profile embeds_once profile_kids_type" do
      Profile.new.should respond_to(:kids_type) 
    end
    
    it "profile embeds_once profile_parent_type" do
      Profile.new.should respond_to(:parent_type) 
    end
  end
end
