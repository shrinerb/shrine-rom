require "views/albums/base"

module Views
  module Albums
    class New < Base
      expose :album_form do |validation: nil|
        Forms::Album.from_validation(validation)
      end

      expose :photos do
        []
      end
    end
  end
end
