require "takeoff/stage/base"

module Takeoff
  module Stage
    module Heroku
      class VerifyServerNotAlreadyUpToDate < Base
        def call(env)
          if env[:deployed_commit] == env[:new_commit]
            raise "The server is already up to date."
          end

          @app.call(env)
        end
      end
    end
  end
end