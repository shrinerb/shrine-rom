require "sucker_punch"

module Jobs
  class Base
    include ::SuckerPunch::Job
    include Import[:inflector]

    def resolve_repository(entity_class)
      entity_name = inflector.underscore(inflector.demodulize(entity_class))

      Container["persistence.repositories.#{entity_name}"]
    end
  end
end
