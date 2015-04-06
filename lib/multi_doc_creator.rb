class MultiDocCreator < Struct.new(:document, :profile_id)

  def perform
    profile = Profile.where(id: profile_id).first
    file_name = Time.now.strftime("%Y%m%d%H%M%S%L-%12N")
    temp_path = "#{Rails.root.join('tmp')}/uploader-documents/color/#{document.id}-#{Time.now.strftime("%Y%m%d%H%M%S%L-%12N")}"
    FileUtils::mkdir_p temp_path
    doc_urls = []
    Document.in(id: document.doc_ids).asc(:created_at).each_with_index do |document|
      unless document.extension_is?(:pdf)
        doc_urls << document.attachment.url
      end
    end
    # convert all into single pdf
    system <<-COMMAND
       #{Document.pdf_conversion_cmd(doc_urls.join(' '))} #{temp_path}/color.pdf
    COMMAND
    test_photo = ActionDispatch::Http::UploadedFile.new({filename: "#{file_name}.pdf",
                                                         type: 'application/pdf',
                                                         tempfile: File.new(File.new("#{temp_path}/color.pdf"))
                                                        })
    #change category_id as user selected
    if document.update_attributes(attachment: test_photo)
      # document.attachment.preload_image_to_cdn("original")
      document.set(attachment_processing: false)
      FileUtils.rm_rf(Dir["#{temp_path}"]) # remove directory from tmp
    end
  end
end