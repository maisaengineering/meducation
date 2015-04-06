require 'spec_helper'

describe ProfilesController do
  
  def valid_attributes
    { parent_type: {
      _type: "ProfileParentType",
      profiles_manageds: [{child_relationship: "Father",
                        kids_profile_id: "500ec74c02915b0002000031"
                      },
                      {
                        child_relationship: "Father",    
                        kids_profile_id: "500ed4ca02915b0002000058"
                      }
                    ],
                    lname: "Reddy",
                    parent_id: "KL750360",
                    fname: "Abhay",
                    phone_numbers: [{type: "Mobile",contact: "011"},
                                    {type: "Home",contact: "022"},
                                    {type: "Work",contact: "033"}
                                  ],
                    email: "abhay@gmail.com"
             }
    }
  end
  
  def build_child
   @profile = Profile.new
   @parent = @profile.parent_profiles.build     
   1.times {@parent.phone_numbers.build}
   1.times {@parent.profiles_manageds.build}
   @email = 'abhay@gmail.com'
  end
  
  describe "GET new" do
    
    before :each do
      build_child
    end
    
    it "assigns a new profile as @profile" do
      @profile.should be_a_new(Profile)
      @profile_created = Profile.create! valid_attributes
      if @email
        
      end
      #measurements.should be_valid
      #contacts.should be_valid
    end
  end


end
