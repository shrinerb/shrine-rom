require "jobs/base"

module Jobs
  module Attachment
    class Promote < Jobs::Base
      def perform(attacher_class, entity_class, entity_id, name, file_data)
        attacher_class = Object.const_get(attacher_class)
        repository     = resolve_repository(entity_class)
        entity         = repository.find(entity_id)

        attacher = attacher_class.retrieve(
          entity:     entity,
          name:       name,
          file:       file_data,
          repository: repository,
        )

        attacher.create_derivatives if entity.is_a?(Entities::Album)
        attacher.atomic_promote
      rescue Shrine::AttachmentChanged, ROM::TupleCountMismatchError
        # attachment has changed or record has been deleted, nothing to do
      end
    end
  end
end
