class ImageResizer
  include Import[:processor]

  def call(file, width, height)
    processor
      .source(file)
      .resize_to_limit!(width, height)
  end
end
