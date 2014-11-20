require "shellwords"

module Takeoff
  module Helpers
    def log(message = nil)
      puts
      puts "🚀  #{message}" if message
    end

    def execute(command)
      puts "$ #{command}"
      value = `#{command}`
      puts value

      raise unless $?.success?
      
      value
    end

    def latest_commit(branch)
      `git rev-parse --verify #{branch}`.strip
    end

    def diff(from, to, files, name_only: false)
      files.select! { |file| File.exist?(file) }
      `git diff #{from}..#{to} -U0 #{"--name-only" if name_only} #{files.join(" ")}`
    end

    def file_has_changed_locally?(file)
      `git ls-files -o -m -d --exclude-standard | grep -E #{Shellwords.escape(file)}`
      $?.success?
    end

    def files_have_changed?(from, to, files)
      !diff(from, to, files, name_only: true).blank?
    end

    def branches_up_to_date?(a, b)
      latest_commit(a) == latest_commit(b)
    end
  end

  extend self
end