class HomeController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :change_url

  layout false, except: ['index']
  def index
    reset_session
    @organizations = Organization.scoped
  end
end
