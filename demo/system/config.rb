require "dry-configurable"

class Config
  extend Dry::Configurable

  setting :secret, "87a8b052df6d426e4e0123789bc7f505"
  setting :database_url, "sqlite://database.sqlite3"
end
