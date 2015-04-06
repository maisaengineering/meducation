class JsonTemplate

  WORKFLOW_TYPES =  {normal: 'Normal', appl_form: 'Application Form', auto: 'Auto at acceptance' }.freeze

  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  include Mongoid::Attributes::Dynamic



  field :organization_id
  field :season_id, :type => String
  field :category, :type => String
  field :form_name, :type => String
  field :workflow, :type => String
  field :content, :type => String
  field :form_status, :type => String, :default => 'inactive'
  field :user_ip, :type => String
  field :user_id, :type => String


  #--------- Relations
  belongs_to :season, index: true
  belongs_to :organization ,foreign_key: :organization_id
  has_many :notifications

  index({ workflow: 1, form_name: 1, form_status:1 }, { background: true })
  index "season_id" => 1
  index "organization_id" => 1

  #----------Scoped
  scope :normal,where(workflow: WORKFLOW_TYPES[:normal])
  scope :auto,where(workflow: WORKFLOW_TYPES[:auto])

  class << self
    def template_by_type_n_season(type = WORKFLOW_TYPES[:appl_form], season)

      unless season
        return nil;
      end

      # grab form type template for the applying season
      form = JsonTemplate.where(:workflow => JsonTemplate::WORKFLOW_TYPES[:appl_form], :season_id => season).first

      # grab template id
      form_id = form.id unless form.nil?

      # JSON parse template content
      json_template = JSON.parse form.content
      return form_id, json_template
    end

    def nested_hash_value(obj, key, uniq)
      if obj.is_a?(Hash) && obj.has_value?(key) && (obj.fetch("unique", "") == uniq)
        obj
      elsif obj.respond_to?(:each)
        r = nil
        obj.find{ |*a| r=nested_hash_value(a.last,key, uniq) }
        r
      end
    end
    def label_name(bucket,key)
      JsonTemplate.nested_hash_value(JSON.parse(self.content), key, bucket)["name"] rescue key
    end
  end

  #-------------- Instance methods

  # returns keys , labes for a given bucket
  def keys_and_labels(bucket)
    json = JSON.parse(content)
    result = {}
    json['form']['panel'].each do  |panel|
      begin
        panel['field'].each do |field|
          result[field['id']] = field['name'] if field['unique'].eql?(bucket) unless field['id'].eql?('ack_date') or field['id'].eql?('ack_signature')
        end
      rescue
        # panel['field'] is not an array or its a fieldgroup (i.e; "fieldgroup"=>{"multiply"=>"true..."} etc ) -->parent bucket
      end
    end
    result
  end

  def json_keys_and_labels
    json = JSON.parse(content)
    result = {}
    json['form']['panel'].each do  |panel|
      begin
        panel['field'].each do |field|
          result[field['id']] = field['name'] unless field['id'].eql?('ack_date') or field['id'].eql?('ack_signature')
        end
      rescue
        # panel['field'] is not an array or its a fieldgroup (i.e; "fieldgroup"=>{"multiply"=>"true..."} etc ) -->parent bucket
      end
    end
    result
  end

  def export_keys_and_labels(bucket,keys_and_labels=[])
    json = JSON.parse(content)
    json['form']['panel'].each do  |panel|
      begin
        panel['field'].each do |field|
          keys_and_labels << {field['id']=> field['name']} if field['unique'].eql?(bucket) unless field['id'].eql?('ack_date') or field['id'].eql?('ack_signature')
        end
      rescue
        # panel['field'] is not an array or its a fieldgroup (i.e; "fieldgroup"=>{"multiply"=>"true..."} etc ) -->parent bucket
      end
    end
    keys_and_labels
  end

  def parent_column_names
    json = JSON.parse(content)
    result = []
    json['form']['panel'].each do  |panel|
      begin
        panel['fieldgroup']['field'].each do |field|
          result = field['selection_list'] if field['id'].eql?('child_relationship')
        end
      rescue
        # panel['field'] is not an array or its a fieldgroup (i.e; "fieldgroup"=>{"multiply"=>"true..."} etc ) -->parent bucket
      end
    end
    result
  end

  # Returns label name by key for specified bucket
  #ex : json_template.label_name('univ','fname') ---> First name
  def label_name(bucket,key)
    JsonTemplate.nested_hash_value(JSON.parse(self.content), key, bucket)["name"] rescue nil
  end

  #season embedded in organization so get season through org
  # #it is good if season_id is stored as objectId
  def season
    organization.seasons.find(season_id)
  end
  #to get all organization_memberships requested by this template
  def organization_memberships
    season_ids = []
    season_ids = workflow.eql?('Normal') ? notifications.submitted.map(&:season_id) : notifications.map(&:season_id)
    organization.organization_memberships.where(:"seasons._id".in => season_ids)
    #season_ids = workflow.eql?('Normal') ? notifications.submitted.map(&:season_id) : notifications.map(&:season_id)
    #organization.organization_memberships.where(:"seasons._id".in => season_ids)

  end

  #returns th total number of requested count for this template,i.e document_definition_id exists count in notifications
  def requested_count
    notifications.count
  end
  #returns th total number of submitted count for this template
  def submitted_count
    notifications.submitted.count
  end


  def export_form_data
    organization.export_profile_data(organization_memberships.map(&:profile_id),season._id,self,false)
=begin
    require 'csv'
    column_key_names = []
    org_column_names = []
    keys_values_univ =[]
    keys_values_org = []
    org_col_names_without_seas = []
    col_key_name_parent = []
    keys_values_org_in_pro = []
    column_par_key_name = []
    keys, values,seas_key_val = [],[], []
    filename = "#{Rails.root}/tmp/profiles.csv"
    File.delete(filename) if File.exist?(filename)
    organization_memberships.each do |organization_membership|
      profile = Profile.where('_id' => organization_membership.profile_id).first
      column_key_names = profile.kids_type.safe_attr_hash.keys unless column_key_names == profile.kids_type.safe_attr_hash.keys
      keys_values_univ = column_key_names.each_with_object({}) { |e,m| m[e] = self.label_name('univ', e) unless self.label_name('univ', e).eql?(e) }

      keys_values_org_in_pro = col_key_name_parent.each_with_object({}) { |e,m| m[e] = self.label_name('parent', e) unless self.label_name('parent', e).eql?(e) }

      org_column_names = organization_membership.seasons.first.attributes.keys  unless org_column_names == organization_membership.seasons.first.attributes.keys

      org_col_names_without_seas = organization_membership.attributes.keys  unless org_col_names_without_seas == organization_membership.attributes.keys
      seas_key_val = org_column_names.each_with_object({}) { |e,m| m[e] = self.label_name('seas', e) unless self.label_name('seas', e).eql?(e) }
      parent_profile_key_val = column_par_key_name.each_with_object({}) { |e,m| m[e] = self.label_name('parent', e) unless self.label_name('parent', e).eql?(e) }
      keys_values_org = org_col_names_without_seas.each_with_object({}) { |e,m| m[e] = self.label_name('org', e) unless self.label_name('org', e).eql?(e) }


    end
    csv_string = CSV.open(filename, 'w') do |csv|
      csv << keys_values_univ.values + keys_values_org_in_pro.values + keys_values_org.values + seas_key_val.values
      organization_memberships.each do |organization_membership|

        profile = Profile.where('_id' => organization_membership.profile_id).first

        Profile.where("parent_type.profiles_manageds.kids_profile_id" => profile.id.to_s).each_with_index { |parent, index|
          p_attr_hash = parent.parent_type.safe_attr_hash
          p_attr_hash.delete_if { |k, v| v.blank? or ['phone_numbers'].include?(k) }
          p_attr_hash.each { |k, v|
            relationship = parent.parent_type.profiles_manageds.first.child_relationship
            temp = self.label_name('parent', k)
            if temp != k
              if temp == 'Parent relationship'
                relationship = v

              end
              if temp != "Parent relationship"

                keys << "#{relationship} #{temp}"
                values << v
              end
            end

          }

        }
        csv << profile.kids_type.attributes.values_at(*keys_values_univ.keys) + profile.kids_type.attributes.values_at(*keys_values_org_in_pro.keys) + organization_membership.attributes.values_at(*keys_values_org.keys) + organization_membership.seasons.first.attributes.values_at(*seas_key_val.keys)
      end
    end

    Notifier.delay.export_form_details(organization.email,form_name,season.season_year)
=end
  end

end
