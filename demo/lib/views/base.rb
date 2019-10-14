require "dry/view"

module Views
  class Base < Dry::View
    config.paths = [Container.root.join("templates")]
    config.layout = "application"
  end
end
