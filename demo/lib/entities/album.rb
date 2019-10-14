require "entities/base"
require "uploaders/image"

module Entities
  class Album < Base
    include Uploaders::Image::Attachment(:cover_photo)
  end
end
