require "takeoff/stage/base"

module Takeoff
  module Stage
    class PointCheckpointToDevelopment < Base
      def call(env)
        return @app.call(env) if env[:development_branch] == env[:checkpoint_branch]

        log     "Pointing checkpoint branch to development branch"
        execute "git checkout #{env[:checkpoint_branch]}"

        begin
          execute "git reset --hard #{env[:development_branch]}"
        ensure
          execute "git checkout #{env[:development_branch]}"
        end

        @app.call(env)
      end
    end
  end
end