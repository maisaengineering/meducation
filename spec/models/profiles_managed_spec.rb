require 'spec_helper'

describe ProfilesManaged do
  describe "Associations" do
    it "should embedded_in profile_parent_type" do
      ProfilesManaged.new.should respond_to(:profile_parent_type)
    end
  end
end
