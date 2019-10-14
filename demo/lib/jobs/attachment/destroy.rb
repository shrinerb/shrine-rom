require "jobs/base"

module Jobs
  module Attachment
    class Destroy < ::Jobs::Base
      def perform(attacher_class, data)
        attacher_class = Object.const_get(attacher_class)

        attacher = attacher_class.from_data(data)
        attacher.destroy
      end
    end
  end
end
