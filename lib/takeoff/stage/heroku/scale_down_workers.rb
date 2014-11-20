require "takeoff/stage/base"

module Takeoff
  module Stage
    module Heroku
      class ScaleDownWorkers < Base
        def call(env)
          unless env[:dangerous]
            log "Skipping scaling down workers because nothing dangerous is going on"
            
            return @app.call(env) 
          end
          
          number_of_workers = execute(
            "heroku ps --remote #{env[:server_remote]} | grep '^worker.' | wc -l | tr -d ' '"
          ).to_i

          return @app.call(env) if number_of_workers == 0

          log     "Scaling down workers"
          execute "heroku scale worker=0 --remote #{env[:server_remote]}"

          begin
            @app.call(env)
          ensure
            log     "Scaling up workers"
            execute "heroku scale worker=#{number_of_workers || 0} --remote #{env[:server_remote]}"
          end
        end
      end
    end
  end
end