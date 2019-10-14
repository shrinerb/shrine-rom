require "views/base"
require "forms/album"
require "contracts/album"
require "uploaders/image"

module Views
  module Albums
    class Base < Views::Base
      include Import[
        album_repo: "persistence.repositories.album",
        photo_repo: "persistence.repositories.photo",
      ]

      expose :image_types do
        Uploaders::Image::ALLOWED_TYPES
      end
    end
  end
end
