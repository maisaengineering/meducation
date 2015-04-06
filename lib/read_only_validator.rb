class ReadOnlyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if !record.from.to_a.include?(Role::NAMES[:super_admin]) and (!record.send("#{attribute.to_s}_was").blank? and record.send("#{attribute.to_s}_changed?"))
      record.errors[attribute] << (options[:message] || "is readonly field, can't be updated")
    end
  end
end