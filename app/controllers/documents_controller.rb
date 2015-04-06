class DocumentsController < ApplicationController
  layout 'parent_layout', only: [:index]
  before_filter :find_profile, except: [:document_buttons, :full_view]
  #before_filter :find_hospital_and_memberships, except: [:original_document, :change_photo_id, :child_node, :multiple_documents, :document_buttons]
  before_filter :find_document, only: [:edit, :show, :share, :update, :destroy, :original_document]
  before_filter :find_memberships, except: [:existing, :original_document, :change_photo_id, :child_node, :multiple_documents, :document_buttons]
  before_filter :find_document_definition, only: [:new, :create, :share]
  before_filter :trackUserDefinedTags, only: [:accept_and_save, :update]
  skip_before_filter :verify_authenticity_token, :only => [:destroy]

  def index
    #get all the top categories ,without children
    @categories = Category.roots
    session.delete(:doc_ids) if session[:doc_ids]
  end

  def accept_and_save
    session[:doc_ids] = session[:doc_ids] || []
    if params[:document][:multi_upload].eql?('true')
      @document = Document.new(params[:document])
      if @document.category.name.eql?(Document::PHOTOGRAPH)
        @document.multi_upload = false
        @document.save
        render js: "window.location.href = '#{documents_path(@document.profile_id, clicked_on: @document.category_name)}'"
      else
        session[:doc_ids].push(@document.id)  if @document.save
      end
    else
      #raise params.inspect
      if session[:doc_ids].size ==1
        params[:document].delete_if { |key, value| key.eql?("attachment") or key.eql?("source") }
        @document= Document.where(:id.in => session[:doc_ids]).first
        @document.update_attributes(params[:document].merge!({attachment_processing: true}))
        @document.delay(queue: 'single_doc_conversion').recreate_delayed_versions! unless @document.tags.include?(Document::PHOTOGRAPH)
      elsif session[:doc_ids].size > 1
        params[:document].delete_if { |key, value| key.eql?("attachment") or key.eql?("source") }
        params[:document].merge!(doc_ids: session[:doc_ids])
        @document = Document.create(params[:document].merge!({attachment_processing: true}))
        Delayed::Job.enqueue MultiDocCreator.new(@document, @profile.id), queue: 'multi_doc_conversion'
      end
      session.delete(:doc_ids) if session[:doc_ids]
      render js: "window.location.href = '#{documents_path(@document.profile_id, clicked_on: @document.category_name)}'"
    end
  end

  def new
    @document = @kid_profile.documents.build
  end

  def create
    @document = Document.new(params[:document].merge!({attachment_processing: true}))
    @document.multi_upload = true unless  @document.category.name.eql?(Document::PHOTOGRAPH)
    if @document.save
      @document.update_attributes(multi_upload: false) unless  @document.category.name.eql?(Document::PHOTOGRAPH)
      @document.delay(queue: 'single_doc_conversion').recreate_delayed_versions! unless @document.tags.include?(Document::PHOTOGRAPH)
      share_to_definition #share the document for for given definition
      redirect_to document_path(@profile.id, @document)
    else
      render 'new'
    end
  end

  def edit
    @categories = Category.roots
    @user_tag = @parent_profile.user_tags.where(id: params[:user_tag]).first
    render layout: false
  end

  def show

  end

  def update
    if params[:replace_doc].eql?('yes') # Replacing the document from old-org UI
      @old_doc = @document
      @notification = Notification.where(document_id: @old_doc.id).first
      redirect_to document_path(@kid_profile ? @kid_profile.id : current_user.parent_profile.id, @old_doc) and return if  params[:document][:attachment].nil? #or  params[:document][:source].nil?
      @new_document = Document.new(params[:document].merge!({attachment_processing: true}))
      @new_document.tags = @old_doc.tags
      @new_document.recent_name = @notification.document_definition.name
      @new_document.multi_upload = @old_doc.multi_upload
      replaced_with = @old_doc.respond_to?(:replaced_with) ? @old_doc.replaced_with : []
      @new_document.write_attribute(:replaced_with,(replaced_with << @old_doc.id).uniq)
      if @new_document.save
        @new_document.update_attributes(multi_upload: false) unless  @new_document.category.name.eql?(Document::PHOTOGRAPH)
        @new_document.delay(queue: 'single_doc_conversion').recreate_delayed_versions! unless @new_document.tags.include?(Document::PHOTOGRAPH)
        Notification.where(document_id: @old_doc.id).update_all(document_id: @new_document.id,user_id: current_user.id, acknowledgment_date: Time.now)
        #increment submitted count to capture resubmitting the form or newly submitting
        @new_document.shared_with.map(&:organization_id).uniq.each { |organization_id| Notifier.document_replaced(organization_id, @new_document, @profile).deliver }
        redirect_to document_path(@kid_profile ? @kid_profile.id : current_user.parent_profile.id, @new_document) and return
      else
        render 'show'
      end
    else
      if @document.update_attributes(params[:document])
        redirect_to documents_path(@kid_profile ? @kid_profile : current_user.parent_profile)
      else
        #render validations
      end
    end
  end

  def destroy

    @document.destroy
    redirect_to documents_path(@kid_profile ? @kid_profile : current_user.parent_profile)
  end

  def existing
    #raise params.inspect
    if  params.include?(:notification_id) and   !params[:notification_id].eql?("")
      find_document_definition
    else
      find_document
    end
    name= @document_definition ? @document_definition.name : @document.category.name
    profile_ids = @kid_profile ? @kid_profile.parent_profiles.map(&:id).push(@kid_profile.id) : @parent_profile.id
    if name.to_s.downcase.eql?('photograph of child') or name.eql?(Document::PHOTOGRAPH)
      @documents =  Document.in(profile_id: profile_ids, tags_array: Document::PHOTOGRAPH).single
    else
      @documents = Document.in(profile_id: profile_ids).single.nin(tags_array: Document::PHOTOGRAPH)
    end
    render layout: false
  end

  #share the document for given definition
  def share
    share_to_definition
    redirect_to document_path(@profile.id, @document)
  end

  def share_to_definition
    @notification.update_attributes(document_id: @document.id, is_accepted: 'submitted', user_id: current_user.id, acknowledgment_date: Time.now)

    #To change alerts outstanding status
    org_seas = @notification.organization_membership.seasons
    org_seas.each do |seas|
      status = seas.notifications.alerts.requested.count > 0 ? true : false
      seas.update_attribute(:alerts_outstanding, status)
    end
    #increment submitted count to capture resubmitting the form or newly submitting
    @notification.inc(submitted_count: 1)
    #push the document_definition name to names of the document
    #@document.update_attribute(:tags_array, @document.tags_array.push(@notification.document_definition.name))
    #send an email to org-admin
    Notifier.org_doc_submission(@profile, @notification, @parent_profile).deliver
    #send an email to parents who managing this kid (for first time submitting)
    if @notification.submitted_count == 1
      parents = Profile.where("parent_type.profiles_manageds.kids_profile_id" => @profile.id.to_s).subscribed_org_emails
      parents.each do |parent|
        recipient = parent.parent_type.email
        unless recipient.blank?
          Notifier.parent_doc_submission(recipient, @kid_profile, @notification, @parent_profile).deliver
        end
      end
    end
  end

  def change_photo_id
    @document = @kid_profile.documents.create(params[:document])
    redirect_to :back
  end

  # =============== Methods supporting Ajax call from tree view ========
  def child_node
    @category = Category.find(params[:category])
    render layout: false
  end

  def multiple_documents
    @category = Category.where(id: params[:category]).first || @parent_profile.user_tags.where(id: params[:category]).first
    @documents = documents_vault(@category)
    render layout: false
  end

  def original_document
    render layout: false
  end

  def document_buttons
    #@category = Category.where(id: params[:category]).first  || @parent_profile.user_tags.where(id: params[:category]).first
    document = Document.where(id: params[:document_id]).first
    render partial: 'document_buttons', locals: {document: document, category_id: params[:category_id]}
  end

  def full_view
    @document = Document.find(params[:id])
    respond_to do |format|
      format.pdf do
        if @document.respond_to?(:doc_ids)
          multiple_color_docs_on_fly
        elsif @document.extension_is?(:pdf)
          color_pdf_on_fly
        else
          single_color_doc_on_fly
        end
      end
    end
  end

  def bw_view
    @document = Document.find(params[:id])
    respond_to do |format|
      format.pdf do
        if @document.respond_to?(:doc_ids)
          multiple_bw_docs_on_fly
        elsif @document.extension_is?(:pdf)
          black_and_white_pdf_on_fly
        else
          single_bw_doc_on_fly
        end
      end
    end
  end


  private

  def find_document
    @document = Document.find(params[:id])
  end

  def find_document_definition
    @notification = Notification.find(params[:notification_id])
    @document_definition = @notification.document_definition
  end

  def trackUserDefinedTags
    if params[:document].include?(:tags)
      tags = params[:document][:tags].split(',')
      tags.map(&:strip!)
      tags.uniq.each do |tag|
        user_tag= @parent_profile.user_tags.where(tag: tag).first ||@parent_profile.user_tags.create(tag: tag, category_ids: params[:document][:category_id].to_a)
        if !user_tag.nil? and !user_tag.category_ids.include?(params[:document][:category_id])
          begin
            user_tag.update_attributes(category_ids: user_tag.category_ids.push(params[:document][:category_id]))
          rescue
            next
          end
        end
      end
    end
  end

  def multiple_color_docs_on_fly
    temp_path = "#{Rails.root.join('tmp')}/onfly-documents/color/#{Time.now.strftime("%Y%m%d%H%M%S%L-%12N")}-#{rand.to_s[2..11]}"
    FileUtils::mkdir_p temp_path
    doc_urls = []
    Document.in(id: @document.doc_ids).asc(:created_at).each_with_index do |document,index|
      unless document.extension_is?(:pdf)
        doc_urls << document.attachment.url
      end
    end
    system <<-COMMAND
#{Document.pdf_conversion_cmd(doc_urls.join(' '))} #{temp_path}/color.pdf
    COMMAND
    color_pdf_file = "#{temp_path}/color.pdf"
    send_file(color_pdf_file, filename: "converted-pdf-#{@document.display_name}.pdf", disposition: 'inline', type: "application/pdf")
    #FileUtils.rm_rf(Dir["#{temp_path}"]) # remove directory from tmp(using scheduler) # Heroku by default delets after some time
    #FileUtils.remove_dir "#{Rails.root}/public/folder", true
  end


  def multiple_bw_docs_on_fly
    temp_path = "#{Rails.root.join('tmp')}/onfly-documents/bw/#{Time.now.strftime("%Y%m%d%H%M%S%L-%12N")}-#{rand.to_s[2..11]}"
    FileUtils::mkdir_p temp_path
    doc_urls = []
    Document.in(id: @document.doc_ids).asc(:created_at).each_with_index do |document,index|
      unless document.extension_is?(:pdf)
        doc_urls << document.attachment.url
      end
    end
    system <<-COMMAND
#{Document.pdf_conversion_cmd(doc_urls.join(' '),true)} #{temp_path}/bw.pdf
    COMMAND

    bw_pdf_file = "#{temp_path}/bw.pdf"
    send_file(bw_pdf_file, filename: "converted-bw-pdf_#{@document.display_name}.pdf", disposition: 'inline', type: "application/pdf")
    #FileUtils.rm_rf(Dir["#{temp_path}"]) # remove directory from tmp(using scheduler) # Heroku by default delets after some time
    #TODO remove generated tmp directory
  end

  def single_bw_doc_on_fly
    temp_path = "#{Rails.root.join('tmp')}/onfly-documents/bw/#{Time.now.strftime("%Y%m%d%H%M%S%L-%12N")}-#{rand.to_s[2..11]}"
    FileUtils::mkdir_p temp_path
    system <<-COMMAND
#{Document.pdf_conversion_cmd(@document.attachment.url,true)} #{temp_path}/#{@document.id}.pdf
    COMMAND
    send_file("#{temp_path}/#{@document.id}.pdf", filename: "#{@document.display_name.parameterize}-view-bw.pdf", type: "application/pdf", disposition: 'inline')
  end

  def single_color_doc_on_fly
    temp_path = "#{Rails.root.join('tmp')}/onfly-documents/color/#{Time.now.strftime("%Y%m%d%H%M%S%L-%12N")}-#{rand.to_s[2..11]}"
    FileUtils::mkdir_p temp_path
    system <<-COMMAND
#{Document.pdf_conversion_cmd(@document.attachment.url)} #{temp_path}/#{@document.id}.pdf
    COMMAND
    send_file("#{temp_path}/#{@document.id}.pdf", filename: "#{@document.display_name.parameterize}-full-view.pdf", type: "application/pdf", disposition: 'inline')
  end

  def black_and_white_pdf_on_fly
    temp_path = "#{Rails.root.join('tmp')}/onfly-documents/bw/#{Time.now.strftime("%Y%m%d%H%M%S%L-%12N")}-#{rand.to_s[2..11]}"
    FileUtils::mkdir_p temp_path
    system <<-COMMAND
       convert #{@document.attachment.url} -monochrome -format pdf #{temp_path}/#{@document.id}.pdf
    COMMAND
    send_file("#{temp_path}/#{@document.id}.pdf", filename: "#{@document.display_name.parameterize}-view-bw.pdf", type: "application/pdf", disposition: 'inline')
  end

  def color_pdf_on_fly
    send_file(@document.attachment.url, filename: "#{@document.display_name.parameterize}-full-view.pdf", type: "application/pdf",stream: false, disposition: 'inline')
  end

end
