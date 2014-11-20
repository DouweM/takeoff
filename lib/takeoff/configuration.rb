require "active_support"
require "active_support/hash_with_indifferent_access"
require "logger"
require "middleware"

module Takeoff
  class Configuration
    def plans
      @plans ||= HashWithIndifferentAccess.new
    end

    def [](name)
      name ||= default_plan
      
      plan = name.is_a?(Class) ? name : plans[name]

      if plan.nil?
        raise "Plan '#{name}' is unknown"
      end

      unless plan <= Plan::Base
        raise "Plan '#{name}' doesn't inherit from Takeoff::Plan::Base" 
      end

      plan
    end

    def plan?(name)
      self[name] rescue nil
    end

    def default_plan(name = nil, &block)
      self.default_plan = name            if name
      default_plan.instance_eval(&block)  if block
      
      @default_plan ||= Plan::Default
    end

    def default_plan=(plan)
      @default_plan = self[plan]
    end

    delegate :stages, :env, to: :default_plan

    def plan(name, plan = nil, based_on: default_plan, &block)
      if plan?(name)
        plan ||= self[name]
      else
        plan ||= Plan.const_set(name.to_s.camelize, Class.new(self[based_on]))
        plans[name] = plan
      end

      plan.instance_eval(&block) if block

      plan
    end
  end
end