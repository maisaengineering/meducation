module HospitalsHelper

  def hospital_count(hospital_id)
    HospitalMembership.where(:hospital_id => hospital_id).count
  end

  # use full for organization or hospital or any other partners
  def partner_ref_url(resource)
     uri = URI.parse(root_url)
     uri.query = URI.encode_www_form(partner: resource.name)
     uri.to_s
  end

end
