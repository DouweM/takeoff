require "takeoff/stage/base"

module Takeoff
  module Stage
    class VerifyGithubUpToDate < Base      
      def call(env)
        log     "Fetching from GitHub"
        execute "git fetch #{env[:github_remote]}"

        unless branches_up_to_date?("#{env[:github_remote]}/#{env[:development_branch]}", env[:development_branch])
          raise "GitHub is not up to date on branch '#{env[:development_branch]}'. Pull and push to synchronize your changes first."
        end

        @app.call(env)
      end
    end
  end
end