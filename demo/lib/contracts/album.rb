require "contracts/base"
require "uploaders/image"
require "json"

module Contracts
  class Album < Base
    option :cover_photo_attacher
    option :photos_attachers

    params do
      required(:name).filled(:string)
      optional(:cover_photo)
      optional(:photos).array(:string).each(:filled?)
    end

    # copy any file validation errors into the contract
    rule(:cover_photo) do
      key.failure("must be present") unless cover_photo_attacher.attached?

      cover_photo_attacher.errors.each do |message|
        key.failure(message)
      end
    end

    # copy any file validation errors into the contract
    rule(:photos).each do
      photo_attacher = photos_attachers.fetch(key.path.keys.last)
      photo_attacher.errors.each do |message|
        key.failure(message)
      end
    end
  end
end
