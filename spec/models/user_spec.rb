require 'spec_helper'

describe User do
  describe "Associations" do    
    it "User has_many profile" do
      User.new.should respond_to(:profiles)
    end
  end
end
