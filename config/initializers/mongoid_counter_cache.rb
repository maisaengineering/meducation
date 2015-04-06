module Mongoid
  module CounterCache
    extend ActiveSupport::Concern

    module ClassMethods
      def counter_cache(options)
        name = options[:name]
        counter_field = options[:field]

        after_create do |document|
          relation = document.send(name)
          relation.collection.update(relation._selector, {'$inc' => {counter_field.to_s => 1}}, {:multi => true})
        end

        after_destroy do |document|
          relation = document.send(name)
          relation.collection.update(relation._selector, {'$inc' => {counter_field.to_s => -1}}, {:multi => true})
        end
      end
    end

  end
end
