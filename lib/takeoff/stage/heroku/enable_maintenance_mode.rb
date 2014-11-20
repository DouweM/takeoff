require "takeoff/stage/base"

module Takeoff
  module Stage
    module Heroku
      class EnableMaintenanceMode < Base
        def call(env)
          unless env[:dangerous]
            log "Skipping maintenance mode because nothing dangerous is going on"
            
            return @app.call(env) 
          end

          log     "Enabling maintenance mode"
          execute "heroku maintenance:on --remote #{env[:server_remote]}"

          begin
            @app.call(env)
          ensure
            log     "Disabling maintenance mode"
            execute "heroku maintenance:off --remote #{env[:server_remote]}"
          end
        end
      end
    end
  end
end