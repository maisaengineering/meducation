module ProfilesHelper
  def organization_links(organization_list)
    organization_list.map do |each_org_name|
      link_to "#{each_org_name}", "#"
    end
  end
=begin

  def generate_id(number)
    return  "KL#{number}"
  end
=end
  def membeship_data(season)
    season.membership_enrollment.nil? ?
        removed_att(season.attributes) :
        removed_att(season.membership_enrollment.attributes)
  end
  def decorate_parent_hash(hash)
    content_tag :ul do
      hash.each do |k, v|
        #emailPattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/
        #if emailPattern.match(v)

        concat(content_tag(:li, v))



      end
      # hash.each_pair {|k, v| concat(content_tag(:li, v))}
    end
  end
  def convert_to_male_female(value)
    case value
      when  'Boy'
        'Male'
      when 'Girl'
        'Female'
      else
        value
    end
  end
  def convert_to_boy_girl(value)
    case value
      when 'Male'
        'Boy'
      when 'Female'
        'Girl'
      else
        value
    end
  end

  # Error message display for user register from org side -- on password choose page
  def org_signup_error_message_for(resource,field)
    if resource.errors.messages[field].present?
      content_tag(:label ,style: 'width: 410px !important;') do
        content_tag(:div, resource.errors[field].join(',') ,class: 'formErrorText', id: 'exp_error1')
      end
    end
  end

end
