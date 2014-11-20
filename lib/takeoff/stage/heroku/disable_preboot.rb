require "takeoff/stage/base"

module Takeoff
  module Stage
    module Heroku
      class DisablePreboot < Base
        def run?(env)
          features = `heroku features --remote #{env[:server_remote]}`
          preboot_line = features.split("\n").find { |feature| feature =~ /\A\[[+ ]\] preboot/ }
          preboot_enabled = preboot_line.start_with?("[+]")

          preboot_enabled
        end

        def call(env)
          unless env[:dangerous]
            log "Skipping disabling preboot because nothing dangerous is going on"

            return @app.call(env) 
          end

          return @app.call(env) unless run?(env)

          log     "Disabling preboot"
          execute "heroku features:disable preboot --remote #{env[:server_remote]}"

          begin
            @app.call(env)
          ensure
            log     "Enabling preboot"
            execute "heroku features:enable preboot --remote #{env[:server_remote]}"
          end
        end
      end
    end
  end
end