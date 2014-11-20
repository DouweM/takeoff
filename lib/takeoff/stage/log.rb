require "takeoff/stage/base"

module Takeoff
  module Stage
    class Log < Base      
      def call(env)
        log "Ready for takeoff! Deploying to #{env[:environment]} server..."

        start_time = Time.now

        begin
          @app.call(env)
        rescue
          end_time = Time.now

          log "Deploying failed in #{end_time - start_time} seconds. Takeoff unsuccessful."
          puts

          raise
        else
          end_time = Time.now

          log "Deploying finished in #{end_time - start_time} seconds. Takeoff successful."
        end
      end
    end
  end
end