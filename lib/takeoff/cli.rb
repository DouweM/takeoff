require "thor"

require "takeoff"

module Takeoff
  class CLI < Thor
    default_task :launch

    class_option :config, aliases: "-c", desc: "Path to your Takeoff configuration file. Defaults to ./Launchfile or ./config/takeoff.rb"

    desc "launch [PLAN]", "Deploy using the specified launch plan."

    long_desc <<-LONG_DESC
      Deploys using the specified launch plan.

      PLAN can be any launch plan that comes out of the box or that you've specified in your configuration file.
      PLAN defaults to the contents of the `RACK_ENV` or `RAILS_ENV` environment variable or the default plan set in your configuration file.
    LONG_DESC

    option :skip, type: :array, aliases: "-s", desc: "Space-seperated list of full or partial names of stages to skip. Example: `-s VerifyServerNotAlreadyUpToDate` if you want to re-do a deployment."
    
    def launch(plan = nil)
      setup

      plan ||= ENV["RACK_ENV"] || ENV["RAILS_ENV"]
      plan = Takeoff[plan]

      options[:skip].each do |name| 
        plan.stages.delete(name) 
      end if options[:skip]

      plan.launch
    end

    private
      def setup
        config_path = options[:config]
        config_path ||= "./Launchfile"        if File.exist?("./Launchfile")
        config_path ||= "./config/takeoff.rb" if File.exist?("./config/takeoff.rb")

        raise "Config file not found!" unless config_path

        Takeoff.configure(File.read(config_path), config_path)
      end
  end
end