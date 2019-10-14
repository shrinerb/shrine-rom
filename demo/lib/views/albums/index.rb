require "views/albums/base"

module Views
  module Albums
    class Index < Base
      expose :albums do
        album_repo.all
      end
    end
  end
end
