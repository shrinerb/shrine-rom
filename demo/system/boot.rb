require_relative "container"
require_relative "import"

Container.finalize! do
  Container.resolve(:config)
end

require_relative "application"
