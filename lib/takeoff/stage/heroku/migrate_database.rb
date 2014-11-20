require "takeoff/stage/base"

module Takeoff
  module Stage
    module Heroku
      class MigrateDatabase < Base
        def self.dangerous?(env)
          new(nil).dangerous?(env)
        end

        def dangerous?(env)
          return @dangerous if defined?(@dangerous)

          return @dangerous = false unless run?(env)

          diff = diff(env[:deployed_commit], env[:new_commit], ["db/migrate"])
          
          unsafe_active_record_terms  = /change_column|change_table|drop_table|remove_column|remove_index|rename_column|execute/
          unsafe_mongoid_terms        = /renameCollection|\.drop|$rename|$set|$unset|indexes\.create|indexes\.drop/
          unsafe_terms = Regexp.union(unsafe_active_record_terms, unsafe_mongoid_terms)

          @dangerous = diff.split("\n").any? do |line|
            line =~ unsafe_terms && line !~ /#\s*safe/i
          end
        end

        def run?(env)
          files_have_changed?(env[:deployed_commit], env[:new_commit], ["db/migrate"])
        end
        
        def call(env)
          unless run?(env)
            log "Skipping database migrations"

            return @app.call(env) 
          end

          log     "Running database migrations"
          execute "heroku run rake db:migrate --remote #{env[:server_remote]}"

          # If ActiveRecord needs to rebuild its column name cache, restart the app.
          if dangerous?(env)
            log     "Restarting application"
            execute "heroku restart --remote #{env[:server_remote]}"
          end

          @app.call(env)
        end
      end
    end
  end
end