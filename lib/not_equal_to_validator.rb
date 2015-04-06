class NotEqualToValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.eql?(options[:source_value] || record.instance_eval("#{options[:source].to_s}"))
      record.errors[attribute] << (options[:message] || ("should not be equal to #{options[:source].to_s}"))
    end
  end
end