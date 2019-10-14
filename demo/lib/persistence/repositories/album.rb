require "persistence/repositories/base"

module Persistence
  module Repositories
    class Album < Base[:albums]
      def find_with_photos(album_id)
        albums.combine(:photos).with_pk(album_id).one
      end
    end
  end
end
