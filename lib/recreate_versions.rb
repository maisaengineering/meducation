class RecreateVersions < Struct.new(:document)
  def perform
    # if you want filename as user uploaded time instead of Time.now ,then
    # at line number 22 lib/carrier_wave/change_filename.rb to model.created_at.strftime("%Y%m%d%H%M%S%L-%12N") l
    document.attachment.recreate_versions!
    document.save!
  end
end