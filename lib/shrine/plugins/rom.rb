# frozen_string_literal: true

class Shrine
  module Plugins
    module Rom
      def self.load_dependencies(uploader)
        uploader.plugin :entity
        uploader.plugin :_persistence, plugin: self
      end

      module AttachmentMethods
        # Disables model behaviour for ROM::Struct and Hanami::Entity
        # subclasses.
        def included(klass)
          @model = false if klass < ::Dry::Struct
          super
        end
      end

      module AttacherMethods
        attr_reader :repository

        def initialize(repository: nil, **options)
          super(**options)
          @repository = repository
        end

        # The _persistence plugin uses #rom_persist, #rom_reload and #rom? to
        # implement the following methods:
        #
        #   * Attacher#persist
        #   * Attacher#atomic_persist
        #   * Attacher#atomic_promote
        private

        # Updates the record with attachment column values. Used by the
        # _persistence plugin.
        def rom_persist
          rom.update_record(column_values)
        end

        # Locks the database row and yields the reloaded record. Used by the
        # _persistence plugin.
        def rom_reload
          rom.retrieve_record { |entity| yield entity }
        end

        # Returns true if the data attribute represents a JSON or JSONB column.
        # Used by the _persistence plugin to determine whether serialization
        # should be skipped.
        def rom_hash_attribute?
          return false unless repository

          column = rom.column_type(attribute)
          column && [:json, :jsonb].include?(column.to_sym)
        end

        # Returns whether the record is a ROM entity. Used by the _persistence
        # plugin.
        def rom?
          record.is_a?(::ROM::Struct)
        end

        # Returns internal ROM wrapper object.
        def rom
          fail Shrine::Error, "repository is missing" unless repository

          RomWrapper.new(repository: repository, record: record)
        end
      end

      class RomWrapper
        attr_reader :repository, :record_pk

        def initialize(repository:, record: nil)
          @repository = repository
          @record_pk  = record.send(relation.primary_key)
        end

        def update_record(attributes)
          repository.update(record_pk, attributes)
        end

        def retrieve_record
          case adapter
          when :sql
            repository.transaction do
              yield record_relation.lock.one!
            end
          else
            yield record_relation.one!
          end
        end

        def column_type(attribute)
          # sends "json" or "jsonb" string for JSON or JSONB column.
          # returns nil for String column
          relation.schema[attribute].type.meta[:db_type]
        end

        private

        def record_relation
          case adapter
          when :sql, :mongo   then relation.by_pk(record_pk)
          when :elasticsearch then relation.get(record_pk)
          else
            fail Shrine::Error, "unsupported ROM adapter: #{adapter.inspect}"
          end
        end

        def adapter
          relation.adapter
        end

        def relation
          repository.root
        end
      end
    end

    register_plugin(:rom, Rom)
  end
end
