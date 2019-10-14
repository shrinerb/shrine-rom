require "dry/initializer"
require "entities/album"

module Forms
  class Album
    extend Dry::Initializer

    option :name,        optional: true
    option :cover_photo, optional: true
    option :photos,      default: proc { [] }
    option :errors,      default: proc { [] }

    def cover_photo_url(*args)
      cover_photo_attacher.url(*args)
    end

    def cover_photo_attacher
      attacher = Entities::Album.cover_photo_attacher
      attacher.load_column(cover_photo) if !cover_photo.to_s.empty?
      attacher
    end
  end
end
