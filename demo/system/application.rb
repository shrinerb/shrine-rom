require "roda"
require_relative "../app"

class Application < Roda
  plugin :public

  route do |r|
    r.public # serve static assets

    r.run ShrineTusDemo
  end
end
