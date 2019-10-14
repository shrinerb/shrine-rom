require "shrine"
require "shrine/storage/file_system"

require "jobs/attachment/promote"
require "jobs/attachment/destroy"

module Uploaders
  class Base < ::Shrine
    storages[:cache] = Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache")
    storages[:store] = Shrine::Storage::FileSystem.new("public", prefix: "uploads")

    plugin :rom
    plugin :instrumentation, notifications: Container[:notifications]

    plugin :form_assign
    plugin :cached_attachment_data
    plugin :restore_cached_data

    plugin :determine_mime_type, analyzer: :marcel, log_subscriber: nil

    plugin :derivatives
    plugin :derivation_endpoint, secret_key: Container[:config].secret

    plugin :upload_endpoint
    plugin :backgrounding

    Attacher.promote_block do
      ::Jobs::Attachment::Promote.perform_async(
        self.class.name,
        record.class.name,
        record.id,
        name,
        file_data,
      )
    end

    Attacher.destroy_block do
      ::Jobs::Attachment::Destroy.perform_async(
        self.class.name,
        data,
      )
    end
  end
end
