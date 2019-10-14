require "rom/relation"

module Persistence
  module Relations
    class Photos < ROM::Relation[:sql]
      schema(:photos, infer: true) do
        associations do
          belongs_to :albums
        end
      end
    end
  end
end
