module Mschool
  module FieldChanges

    def add_changes(args)
      @klchnages ||= {}
      args.reject!{|k,v| v.blank?}
      @klchnages.merge!(args)
    end

    def kl_changes
      @klchnages ||= {}
      @klchnages
    end

    def add_changed_fields(changed_fields)
      parents = ["Mother", "Father", "Stepfather", "Stepmother", "Grandmother", "Grandfather", "Guardian", "Other"]
      changed_fields.except!("updated_at", "_id","_type")

      unless changed_fields.blank?
        if parent_type
          self.managed_kids.each do |kid|
            unless kid.organization_memberships.blank?
              kid.organization_memberships.active.each do |org_membership|
                org_email = org_membership.organization.email
                parent_relation = parent_type.profiles_manageds.where(kids_profile_id:  kid.id).first.child_relationship
                Notifier.details_change({parent_relation =>changed_fields}, org_email, kid).deliver
              end
            end
          end
        elsif self.kids_type
          organization_memberships.active.each do |org_membership|
            org_email = org_membership.organization.email
            json_templates = org_membership.organization.json_templates.map(&:json_keys_and_labels).map(&:keys).flatten.uniq
            common_fields = changed_fields.keys & (json_templates + ["zipcode"])
            changed_fields.slice!(*(parents+common_fields))
            unless changed_fields.blank?
              Notifier.details_change(changed_fields, org_email,self).deliver
            end
          end
        end
      end
    end

    handle_asynchronously :add_changed_fields, :queue=>'org_data_changes'

    def search_hash(h, search)
      return h[search] if h.fetch(search, false)
      h.keys.each do |k|
        answer = search_hash(search_hash(h, k), search) if search_hash(h, k).is_a? Hash
        return answer if answer
      end
      false
    end

  end
end
