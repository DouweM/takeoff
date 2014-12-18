require "takeoff/stage/base"

module Takeoff
  module Stage
    module Heroku
      class PrecompileAndSyncAssets < Base
        def run?(env)
          files = %w(app/assets lib/assets vendor/assets Gemfile.lock config/initializers/assets.rb)
          files_have_changed?(env[:deployed_commit], env[:new_commit], files)
        end

        def call(env)
          unless run?(env)
            log "Skipping precompilation of assets"
            
            return @app.call(env)
          end

          begin
            log     "Precompiling assets"
            execute "RAILS_ENV=#{env[:environment]} bundle exec rake assets:precompile"

            log     "Syncing assets"
            execute "RAILS_ENV=#{env[:environment]} bundle exec rake assets:sync"

            if file_has_changed_locally?("public/assets/manifest-#{env[:environment]}.json")
              log     "Committing updated asset manifests"
              execute "git add public/assets/manifest-#{env[:environment]}.json"            
              execute "git commit -m 'Update asset manifest for #{env[:environment]}.' -m '[ci skip]'"

              log     "Pushing development branch to GitHub"
              execute "git push github #{env[:development_branch]}:#{env[:development_branch]} --force"
            end
          ensure
            log     "Deleting precompiled assets"
            execute "git ls-files -o --exclude-standard public/assets | xargs rm"
            # We can't use `rm -r ./public/assets` because we still need the manifest files.
          end

          @app.call(env)
        end
      end
    end
  end
end