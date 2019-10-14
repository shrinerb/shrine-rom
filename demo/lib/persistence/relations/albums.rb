require "rom/relation"

module Persistence
  module Relations
    class Albums < ROM::Relation[:sql]
      schema(:albums, infer: true) do
        associations do
          has_many :photos
        end
      end
    end
  end
end
