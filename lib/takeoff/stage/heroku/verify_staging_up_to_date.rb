require "takeoff/stage/base"

module Takeoff
  module Stage
    module Heroku
      class VerifyStagingUpToDate < Base
        def call(env)
          unless Takeoff.plan?("staging")
            log "WARNING: Skipping verification that the staging server is up to date because a launch plan for the staging environment has not been set up"
            
            return @app.call(env)
          end

          staging_takeoff = Takeoff[:staging]

          log     "Fetching from staging server"
          execute "git fetch #{staging_takeoff.env[:server_remote]}"

          unless branches_up_to_date?("#{staging_takeoff.env[:server_remote]}/master", env[:development_branch])
            raise "The staging server is not up to date with branch '#{env[:development_branch]}'. Deploy to staging first."
          end

          @app.call(env)
        end
      end
    end
  end
end