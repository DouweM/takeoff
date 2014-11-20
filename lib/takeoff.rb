require "active_support/core_ext"

require "takeoff/version"
require "takeoff/configuration"

require "takeoff/plan/base"
require "takeoff/plan/default"

module Takeoff
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure(source = nil, source_location = nil, &block)
      if source
        if source_location
          configuration.instance_eval(source, source_location) 
        else
          configuration.instance_eval(source) 
        end
      end

      if block
        if block.arity == 1
          block.call(configuration)
        else
          configuration.instance_eval(&block)
        end
      end
    end

    delegate :plans, :[], :plan?, :default_plan, to: :configuration

    def logger
      @logger ||= Logger.new
    end
  end

  configure do
    plan :base,     Plan::Base
    plan :default,  Plan::Default
  end
end