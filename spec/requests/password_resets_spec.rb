require 'spec_helper'

describe "PasswordResets" do  
  it "email to user when requesting passward reset" do    
    user = Factory(:user)
    visit new_user_session_path
    click_link "Forgot your password?"
    fill_in "Email", :with => user.email
    click_button "reset password"
    page.should have_content("You will receive an email with instructions about how to reset your password in a few minutes.")    
    page.should have_content("login")
  end  
end
