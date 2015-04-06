require 'spec_helper'

describe OrganizationMembership do
  describe "Associations" do
    it "should embedded_in profile_kids_type" do
      OrganizationMembership.new.should respond_to(:profile_kids_type)
    end
  end
end
