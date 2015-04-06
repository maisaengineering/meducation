require 'spec_helper'

describe ProfileParentType do
  describe "Associations" do
    it "should embedded_in profile" do
      ProfileParentType.new.should respond_to(:profile)
    end
    
    it "should embeds_many phone_numbers" do
      ProfileParentType.new.should respond_to(:phone_numbers)
    end
    
    it "should embeds_many profiles_manageds" do
      ProfileParentType.new.should respond_to(:profiles_manageds)
    end
  end
end
