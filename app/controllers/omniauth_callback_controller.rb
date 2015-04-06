class OmniauthCallbackController < ApplicationController
  #before_filter :register_handlebars,only: :facebook
  before_filter :register_handlebars,only: :facebook
  def facebook
    @milestone = Milestone.find(session[:milestone_id])
    @kid_profile = Profile.find(session[:profile_id])
    @managed_kids = current_user.managed_kids
    #find_hospital_and_memberships
    @design = @milestone.milestone_template.designs.where(id: @milestone.design_id).first
    img_content = @design.content.split(";")
    img_design = img_content.reject{|word| word.include?('-transform') and !word.include?('text')}.join(';')
    file = Tempfile.new([@milestone.milestone_template.name, '.png'], 'tmp', encoding: 'ascii-8bit')
    @template = @handlebars.compile(img_design)
    @kit = IMGKit.new(@template.call(KIDSLINK: kl_data_points('large',@milestone,true)).html_safe, height: 660, width:465, quality: 70)
    @kit.stylesheets << "#{Rails.root}/app/assets/stylesheets/rb_set1.css"
    file.write(@kit.to_png)
    file.flush
    @graph = Koala::Facebook::API.new(env["omniauth.auth"][:credentials].token)
    @graph.put_picture( file.path, {message: @milestone.display_name})
    file.unlink
    session.delete(:milestone_id)
    session.delete(:profile_id)
    if mobile_devices_format?
      redirect_to m_timeseries_path(@kid_profile)
    else
      redirect_to child_dashboard_path(@kid_profile)
    end
  end

  def oauth_failure
    redirect_to root_url
  end

end

