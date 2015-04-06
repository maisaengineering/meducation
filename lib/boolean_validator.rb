class BooleanValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
   unless value.is_a?(Boolean)
      record.errors[attribute] << (options[:message] || "should be Boolean value true (or) false")
    end
  end
end