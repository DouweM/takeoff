require "takeoff/stage/base"

module Takeoff
  module Stage
    class PushToGithub < Base      
      def call(env)
        log     "Pushing checkpoint branch to GitHub"
        execute "git push github #{env[:checkpoint_branch]}:#{env[:checkpoint_branch]} --force"

        @app.call(env)
      end
    end
  end
end