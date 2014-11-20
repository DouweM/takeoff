require "takeoff/stage/base"

module Takeoff
  module Stage
    class StashChanges < Base      
      def call(env)
        status = `git status --untracked-files --short`
        return @app.call(env) if status.blank?

        stash_name = "Takeoff Auto-Stash: #{Time.now}"

        log     "Stashing uncommitted changes"
        execute "git stash save -u #{Shellwords.escape(stash_name)}"

        begin
          @app.call(env)
        ensure
          log "Applying previously stashed uncommitted changes"

          stashes       = `git stash list`
          matched_stash = stashes.split("\n").find { |stash| stash.include?(stash_name) }
          label         = matched_stash.match(/^([^:]+)/)

          execute "git clean -fd"
          execute "git stash apply #{label}"
          execute "git stash drop #{label}"
        end
      end
    end
  end
end