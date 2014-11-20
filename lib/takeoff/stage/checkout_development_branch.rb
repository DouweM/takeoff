require "takeoff/stage/base"

module Takeoff
  module Stage
    class CheckoutDevelopmentBranch < Base
      def call(env)
        previous_branch = `git rev-parse --abbrev-ref HEAD`.strip
        previous_branch = `git rev-parse --verify HEAD`.strip if previous_branch == "HEAD"

        return @app.call(env) if previous_branch == env[:development_branch]

        log     "Checking out development branch"
        execute "git checkout #{env[:development_branch]}"

        begin
          @app.call(env)
        ensure
          log     "Checking out original branch '#{previous_branch}'"
          execute "git checkout #{previous_branch}"
        end
      end
    end
  end
end