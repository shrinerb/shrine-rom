require "views/albums/base"

module Views
  module Albums
    class Create < Base
      expose :album_form do
        Forms::Album.new
      end
    end
  end
end
