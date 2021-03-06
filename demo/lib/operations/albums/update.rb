require "operations/base"
require "contracts/album"

module Operations
  module Albums
    class Update < Base
      include Import[
        album_repo: "persistence.repositories.album",
        photo_repo: "persistence.repositories.photo",
      ]

      def call(album, params)
        attachers = yield assign_files(album, params)
        values    = yield validate(album, params, attachers)
        album     = yield update(album, values, attachers)

        Success(album)
      end

      private

      def assign_files(album, params)
        cover_photo_attacher = album.cover_photo_attacher
        cover_photo_attacher.form_assign(params)

        photos_attachers = Array(params[:photos]).map do |file_data|
          attacher = Entities::Photo.image_attacher
          attacher.assign(file_data)
          attacher
        end

        Success(
          cover_photo_attacher: cover_photo_attacher,
          photos_attachers:     photos_attachers,
        )
      end

      def validate(album, params, attachers)
        contract = Contracts::Album.new(attachers)
        result   = contract.(params)

        if result.success?
          Success(result.to_h)
        else
          Failure(result)
        end
      end

      def update(album, album_values, cover_photo_attacher:, photos_attachers:)
        album_values.delete(:cover_photo)
        album_values.delete(:photos)

        album_values.merge!(cover_photo_attacher.column_values)

        album_repo.update(album.id, album_values)

        photos_attachers.each do |image_attacher|
          photo = photo_repo.create(album_id: album.id, **image_attacher.column_values)

          # set created record instance for promotion
          image_attacher.set_entity(photo, :image)
        end

        # promote cached file and destroy any previous attachments
        [cover_photo_attacher, *photo_attachers].each(&:finalize)

        Success(album)
      end
    end
  end
end
