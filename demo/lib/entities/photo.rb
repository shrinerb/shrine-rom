require "entities/base"
require "uploaders/image"

module Entities
  class Photo < Base
    include Uploaders::Image::Attachment(:image)
  end
end
