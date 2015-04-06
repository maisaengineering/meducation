class Fixnum
  def to_json(options = nil)
    to_s
  end
end

class String
  def to_a
    lines.to_a
  end
end