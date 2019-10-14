require "roda"

require "uploaders/image"

class ShrineRomDemo < Roda
  use Rack::MethodOverride
  plugin :all_verbs

  plugin :indifferent_params

  include Import[album_repo: "persistence.repositories.album"]

  route do |r|
    r.root do
      r.redirect "/albums"
    end

    r.on "albums" do
      r.get true do
        view "albums.index"
      end

      r.get "new" do
        view "albums.new"
      end

      r.post true do
        operation "albums.create", params[:album] do |m|
          m.success do |album|
            r.redirect "/albums/#{album.id}/edit"
          end

          m.failure do |validation|
            view "albums.new", validation: validation
          end
        end
      end

      r.is Integer do |album_id|
        album = album_repo.find_with_photos(album_id) or not_found!

        r.get "edit" do
          view "albums.edit", album: album
        end

        r.put do
          operation "albums.update", album, params[:album] do |m|
            m.success do |album|
              r.redirect "/albums/#{album.id}/edit"
            end

            m.failure do |validation|
              view "albums.edit", album: album, validation: validation
            end
          end
        end

        r.delete do
          operation "albums.delete", album

          r.redirect "/albums"
        end
      end
    end

    r.on "upload" do
      r.run Uploaders::Base.upload_endpoint(:cache)
    end

    r.on "derivations/image" do
      r.run Uploaders::Image.derivation_endpoint
    end
  end

  private

  def view(name, *args)
    Container["views.#{name}"].call(*args)
  end

  def operation(name, *args, &block)
    Container["operations.#{name}"].call(*args, &block)
  end

  def not_found!
    response.status = 404
    request.halt
  end
end
