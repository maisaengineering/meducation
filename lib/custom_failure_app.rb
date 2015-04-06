# By default devise responds with 401(Unauthorized) if user session timed out and any request comes via js
# for html requests it redirects to signin page
# Override FailureApp to redirect to sign in page when request comes via js(ajax)
class CustomFailureApp < Devise::FailureApp
  def redirect_url
    if request.xhr?
      send(:"new_#{scope}_session_path", format: :js)
    else
      super
    end
  end
end