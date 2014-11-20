require "takeoff/helpers"

module Takeoff
  module Stage
    class Base
      include Helpers
      
      def initialize(app)
        @app = app
      end

      def call(env)
        raise NotImplementedError
      end
    end
  end
end