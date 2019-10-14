require "uploaders/base"
require "image_resizer"

module Uploaders
  class Image < Base
    ALLOWED_TYPES  = %w[image/jpeg image/png image/webp]
    MAX_SIZE       = 10*1024*1024 # 10 MB
    MAX_DIMENSIONS = [5000, 5000] # 5000x5000

    THUMBNAILS = {
      small:  [300, 300],
      medium: [600, 600],
      large:  [800, 800],
    }

    RESIZER = ImageResizer.new

    plugin :remove_attachment
    plugin :pretty_location
    plugin :validation_helpers
    plugin :store_dimensions, log_subscriber: nil
    plugin :derivation_endpoint, prefix: "derivations/image"

    Attacher.validate do
      validate_size 0..MAX_SIZE

      if validate_mime_type ALLOWED_TYPES
        validate_max_dimensions MAX_DIMENSIONS
      end
    end

    Attacher.derivatives_processor do |original|
      THUMBNAILS.inject({}) do |result, (name, (width, height))|
        result.merge! name => RESIZER.call(original, width, height)
      end
    end

    Attacher.default_url do |derivative: nil, **|
      file&.derivation_url(:thumbnail, *THUMBNAILS.fetch(derivative)) if derivative
    end

    derivation :thumbnail do |file, width, height|
      RESIZER.call(file, width.to_i, height.to_i)
    end
  end
end
