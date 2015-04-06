require 'spec_helper'

describe PhoneNumber do
  describe "Associations" do
    it "should embedded_in profile_parent_type" do
      PhoneNumber.new.should respond_to(:profile_parent_type)
    end
  end
end
