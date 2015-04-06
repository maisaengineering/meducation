# Support for MongoId random ,in RDBMS we have rand() to get records randomly
# Below is the   random method for MongoId and its a Criteria and still scoped
#Ex: User.random -> default 1 record
# User.random(3) -> to get 3 records randomly
# User.where(:age.gtl > 10).random(2) -> scoped
class Mongoid::Criteria
  def random(n = 1)
    indexes = (0..self.count-1).sort_by{rand}.slice(0,n).collect!
    if n == 1
      return self.skip(indexes.first).first
    else
      return indexes.map{ |index| self.skip(index).first }
    end
  end
end

module Mongoid
  module Finders
    def random(n = 1)
      criteria.random(n)
    end
  end
end