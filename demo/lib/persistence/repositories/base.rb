require "rom/repository"

module Persistence
  module Repositories
    class Base < ::ROM::Repository::Root
      commands :create, update: :by_pk, delete: :by_pk
      struct_namespace ::Entities

      # Makes repositories work with dry-system auto registration.
      def self.new(rom = nil)
        super(rom || Container["persistence.rom"])
      end

      def find(record_id)
        root.fetch(record_id)
      end

      def all
        root.to_a
      end

      def struct(attributes = {})
        tuple = attributes.dup

        root.columns.each do |name|
          tuple[name] = nil unless tuple.key?(name)
        end

        root.mapper.model.new(tuple)
      end
    end
  end
end
