require "dry/system/container"

class Container < Dry::System::Container
  configure do |config|
    config.auto_register = "lib"
  end

  load_paths! "lib"

  register :config do
    require_relative "config"

    Config.config
  end

  register :inflector do
    require "dry/inflector"

    Dry::Inflector.new
  end

  register :notifications, memoize: true do
    require "dry/monitor"

    Dry::Monitor::Notifications.new(:app)
  end

  register :processor do
    require "image_processing/mini_magick"

    ImageProcessing::MiniMagick
  end
end
