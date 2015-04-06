class Notifier < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  layout "email", except: [:welcome_email]
  layout false, only: [:welcome_email]
  #Enable below line for production
  default from: "labs@maisasolutions.com"

  def welcome_email(fname, lname, email)
    @parent_fname = fname
    @parent_lname = lname
    @parent_email = email
    mail(:to => @parent_email, :subject => "Welcome to KidsLink!")
  end

  def details_change(fields, org_email, kid)
    @kid_profile = kid
    @org_email = org_email
    @fields = fields
    mail(:to => @org_email, :subject => "KidsLink: details changed")
  end

  def signup_additional_confirmation(child_fname, other_lname, other_fname, pswd, email, nick_name)
    # raise email.inspect
    @child_fname = child_fname
    @other_lname = other_lname
    @other_fname= other_fname
    @pswd = pswd
    @email = email
    @nick_name =  nick_name
    nickname = [nick_name].flatten.to_sentence
    mail(:to => @email, :subject => "KidsLink: Sign-up confirmation for #{nickname}")
  end

  def signup_additional_confirmation_for_existing(child_fname, other_lname, other_fname, email, nick_name)
    # raise email.inspect
    @child_fname = child_fname
    @other_lname = other_lname
    @other_fname= other_fname
    @email = email
    @nick_name =  nick_name
    nickname = [nick_name].flatten.to_sentence
    mail(:to => @email, :subject => "KidsLink: Sign-up confirmation for #{nickname}")
  end

  def signup_confirmation_first_parent(email, nick_name)
    # raise email.inspect
    @email = email
    @nick_name =  nick_name
    nickname = [nick_name].flatten.to_sentence
    mail(:to => @email, :subject => "KidsLink: Sign-up confirmation for #{nickname}")
  end

  #realated to payment
  def signup_confirmation(reg_email, kids_applied, trans_email, amount, child_lname, nick_name)
    # raise trans_email.inspect
    @child_fname = kids_applied
    @child_lname = child_lname
    @nick_name = nick_name
    @parent_email = reg_email
    @trans_email = trans_email
    @amount = amount
    nickname = [nick_name].flatten.to_sentence
    # emails = @parent_email,@trans_email #not required now.
    mail(:to => @parent_email, :subject => "KidsLink: Sign-up confirmation for #{nickname}")
  end

  def application_confirmation(parent_email, child_fname, org_name, season, session, org_web, nick_name)
    @parent_email = parent_email
    @child_fname = child_fname
    @org_name = org_name
    @season = season
    @session = session
    @org_web = org_web
    @nick_name = nick_name
    nickname = [nick_name].flatten.to_sentence
    mail(:to => @parent_email, :subject => "KidsLink: Registration / Application submitted at #{@org_name} for #{nickname}")
  end


  def status_accepted(season,nick_name, org_name, session, org_prefered_name, alert_forms, parent_email, org_web)
    @season = season
    @session = session
    @nick_name = nick_name
    @org_name = org_name
    @org_prefered_name = org_prefered_name
    @alert_forms = alert_forms
    @parent_email = parent_email
    @org_web = org_web
    mail(:to => @parent_email, :subject => "Status Accepted")
  end

  def status_registered(season,nick_name, org_name, session, parent_email, org_web)
    @season = season
    @session = session
    @nick_name = nick_name
    @org_name = org_name
    @parent_email = parent_email
    @org_web = org_web
    mail(:to => @parent_email, :subject => "Status Registered")
  end

  def org_application(org_admin, season, session, fname, nick_name, lname, created_time,org_id, kid_id)
    @fname = fname
    @lname = lname
    @nick_name = nick_name
    @season = season
    @session = session
    @created_time = created_time
    @org_admin = org_admin
    @org_id = org_id
    @kid_id = kid_id
    mail(:to => org_admin, :subject => "KidsLink: New Application Submitted for #{@fname} #{@lname} (#{@session})")
  end



  def org_form_submission(kid,notification,current_parent,parent_type_profiles, applied_season,organization_membership,json_template, organization,submitted_count)
    #------------------ ------------------------------   Buckets -----
    @organization  = organization
    @parent_type_profiles  = parent_type_profiles
    @kid = kid              #univ
    @parent_type_profile = current_parent.parent_type   #parent
    @applied_season = applied_season                    #seas
    @organization_membership = organization_membership #org
    @created_time = notification.acknowledgment_date
    @json_template = json_template
    @submitted_count = submitted_count
    mail(to: organization.email, subject: "Organization Form Submission")
  end

  def parent_form_submission(recipient,kid,notification,applied_season,organization_membership,json_template,organization,submitted_by)
    @organization  = organization
    @kid = kid
    @applied_season = applied_season
    @organization_membership = organization_membership
    @created_time = notification.acknowledgment_date
    @json_template = json_template
    @submitted_by = submitted_by.parent_type
    mail(to: recipient, subject: "Organization Form Submission")
  end


  def org_doc_submission(kid,notification,submitted_by)
    @kid = kid
    @notification = notification
    @organization_membership = notification.organization_membership
    @organization = @organization_membership.organization
    @applied_season = notification.season
    @submitted_by = submitted_by.parent_type
    mail(to: @organization.email, subject: "Organization Document Submission")
  end

  def parent_doc_submission(recipient,kid,notification,submitted_by)
    @kid = kid
    @notification = notification
    @organization_membership = notification.organization_membership
    @organization = @organization_membership.organization
    @applied_season = notification.season
    @submitted_by = submitted_by.parent_type
    mail(to: recipient, subject: "Organization Document Submission")
  end


  def document_replaced(organization_id,document,profile)
    @document = document
    @kid_profile = profile
    @organization = Organization.find(organization_id)
    @kid_name = "#{profile.kids_type.fname} (#{profile.kids_type.nickname}) #{profile.kids_type.lname}"
    # eg http://localhost:3000/uploads/document/source/51611273c1bb1b0872000003/rubylang.png

    @url = colored_document_url(document)
    mail(to: @organization.email,subject: "Document Replaced for #{@kid_name}")
  end

  def notification_form_alert(org_nickname,org_name,kid_name,season_year,form_name,parent_email)
    @org_nickname = org_nickname
    @org_name = org_name
    @kid_name = kid_name
    @season_year = season_year
    @form_name = form_name
    mail(to: parent_email, subject: "Alert: #{@form_name} requested by #{@org_nickname}")
  end

  def notification_doc_alert(org_nickname,org_name,kid_name,season_year,doc_name,parent_email)
    @org_nickname = org_nickname
    @org_name = org_name
    @kid_name = kid_name
    @season_year = season_year
    @doc_name = doc_name
    mail(to: parent_email, subject: "Alert: #{@doc_name} requested by #{@org_nickname}")
  end


  def export_form_details(org_email,org_name,form_name,season_year,p)  #send an email to client with user attachment
    filename = "#{Rails.root}/tmp/export_profiles-#{Time.now.to_i}.xlsx"
    p.serialize(filename)
    @org_name = org_name
    attachments["#{form_name[0..7]}(#{season_year})#{Time.now.strftime('%d-%b %H:%M')}.xlsx"] = File.read(filename)
    mail(to: org_email,subject: "KidsLink data export")
    File.delete(filename) if File.exist?(filename)
  end

  def hospital_registration_conformation(parent, kid_name,  hospital_id)
    @parent= parent
    @kid_name= kid_name
    @hospital = Hospital.where(id:hospital_id).first
    mail(to: parent[:email], subject: "Kidslink Signup confirmation.")
  end

  def send_login_details(email, name, pass)

    @email = email
    @name = name
    @pass = pass
    mail(to: @email, subject: "Kidslink login details.")
  end

  def invite_mom(inv_id)
    @inv = Invitation.find(inv_id)
    @latest_activity = Activity.any_of({:_type=>'Milestone', :milestone_image.exists=>true},
                                       {:_type=>'Story', :image.exists=>true})
                               .and(profile_id: @inv.profile_id).desc(:created_at).first
    sub = "I just invited you to KidsLink" + (@latest_activity ? " (now comment on my post!)" : "")
    mail(to: @inv.email, subject: sub, from: "#{@inv.profile.profile_full_name} on KidsLink <#{ENV['SENDER']}>", reply_to: @inv.profile.parent_type.email)
  end

  def request_for_sharing_docs(sender,recipient,kids)
    @sender = sender.parent_type
    @recipient = recipient.parent_type
    @kid_full_names = kids.to_a.map(&:full_name)
    @url  = 'http://me.mykidslink.com/'
    mail(to: @recipient.email, subject: 'Document Sharing Permission')
  end

  def ae_alerts(notification, parent_emails)
    @notification = notification
    mail(to: parent_emails, subject: " #{@notification.ae_definition.title}", from: ENV['SENDER'])
  end


  def weekly_export_memberships(recipient,file_name,file_path)
    attachments[file_name] = File.read(file_path)
    mail(to: recipient,subject: "KidsLink Weekly Organization Membership data export")
  end

  private

  def colored_document_url(document)
    if document.tags.include?(Document::PHOTOGRAPH)
      document.source.url
    elsif document.attachment_processing == false
      document.extension_is?(:pdf) ? document.attachment.url : document.attachment.converted_pdf.url
    elsif document.attachment_processing == true
      document.attachment.url
    end
  end

end


                  