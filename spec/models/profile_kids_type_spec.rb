require 'spec_helper'

describe ProfileKidsType do
  describe "Associations" do
    it "should embedded_in profile" do
      ProfileKidsType.new.should respond_to(:profile)
    end
    
    it "should embeds_many organization_memberships" do
      ProfileKidsType.new.should respond_to(:organization_memberships)
    end
    
    it "profile embeds_once organization_enrollment" do
      ProfileKidsType.new.should respond_to(:organization_enrollment) 
    end
  end
end
