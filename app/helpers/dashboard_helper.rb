module DashboardHelper

  def pre_fills(object, attribute)
    unless object.nil?
      object.pre_fill(attribute)
    end
  end

end
