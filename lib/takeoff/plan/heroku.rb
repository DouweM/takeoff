require "takeoff/plan/default"

require "takeoff/stage/heroku/remember_commits"
require "takeoff/stage/heroku/verify_server_not_already_up_to_date"
require "takeoff/stage/heroku/disable_preboot"
require "takeoff/stage/heroku/scale_down_workers"
require "takeoff/stage/heroku/enable_maintenance_mode"
require "takeoff/stage/heroku/push_to_server"
require "takeoff/stage/heroku/migrate_database"

module Takeoff
  module Plan
    class Heroku < Default
      env.merge!(
        server_remote: "heroku"
      )

      stages do
        insert_after Stage::Log,
          Stage::Heroku::RememberCommits

        insert_after Stage::VerifyGithubUpToDate, 
          Stage::Heroku::VerifyServerNotAlreadyUpToDate

        insert_after Stage::PointCheckpointToDevelopment, [
          Stage::Heroku::DisablePreboot,
          Stage::Heroku::ScaleDownWorkers,
          Stage::Heroku::EnableMaintenanceMode,

          Stage::Heroku::PushToServer,

          Stage::Heroku::MigrateDatabase
        ]
      end
    end
  end
end

Takeoff.configure do
  plan :heroku, Takeoff::Plan::Heroku
end