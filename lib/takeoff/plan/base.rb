require "active_support"
require "active_support/core_ext"
require "middleware"
require "takeoff/ext/middleware_builder"

module Takeoff
  module Plan
    class Base
      class << self
        def build_plan(name, &block)
          plan = Class.new(self, &block)
          Plan.const_set(name.to_s.camelize, plan)
        end

        def stages(&block)
          @stages ||= default_stages

          @stages.instance_eval(&block) if block

          @stages
        end

        def env
          @env ||= default_env
        end

        def launch(env = {})
          new.launch(env)
        end
        
        private
          def base?
            self.superclass == ::Object
          end

          def default_stages
            if base?
              Middleware::Builder.new
            else
              parent_stages = self.superclass.stages
              Middleware::Builder.new { use parent_stages }
            end
          end

          def default_env
            env = if base?
              {}
            else
              self.superclass.env.dup
            end

            env.merge!(plan: self)
          end
      end

      def launch(env = {})
        env = self.class.env.merge(env)
        self.class.stages.call(env)
      end
    end
  end
end