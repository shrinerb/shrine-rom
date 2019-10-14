require "dry/monads"
require "dry/monads/do"
require "dry/matcher"
require "dry/matcher/result_matcher"

module Operations
  class Base
    include Dry::Monads[:result]
    include Dry::Monads::Do.for(:call)
    include Dry::Matcher.for(:call, with: Dry::Matcher::ResultMatcher)
  end
end
