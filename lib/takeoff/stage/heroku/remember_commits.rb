require "takeoff/stage/base"

module Takeoff
  module Stage
    module Heroku
      class RememberCommits < Base      
        def call(env)
          log     "Fetching from server"
          execute "git fetch #{env[:server_remote]}"
          
          env[:deployed_commit] = latest_commit("#{env[:server_remote]}/master")
          env[:new_commit]      = latest_commit(env[:development_branch])

          @app.call(env)
        end
      end
    end
  end
end