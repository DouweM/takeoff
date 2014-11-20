require "takeoff/stage/base"

module Takeoff
  module Stage
    class LookOutForDanger < Base      
      def call(env)
        env[:stages]            = env[:plan].stages.middlewares
        env[:dangerous_stages]  = env[:stages].select { |stage| stage.respond_to?(:dangerous?) && stage.dangerous?(env) }
        env[:dangerous]         = env[:dangerous_stages].count > 0

        @app.call(env)
      end
    end
  end
end