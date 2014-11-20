require "takeoff/stage/base"

module Takeoff
  module Stage
    module Heroku
      class PushToServer < Base
        def call(env)
          log     "Pushing to server"
          execute "git push #{env[:server_remote]} #{env[:checkpoint_branch]}:master --force"

          @app.call(env)
        end
      end
    end
  end
end