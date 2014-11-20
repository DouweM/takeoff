require "uri"
require "net/http"
require "json"

require "takeoff/stage/base"

module Takeoff
  module Stage
    class VerifyCircleCiStatus < Base      
      def call(env)
        unless env[:github_repo] && ENV["GITHUB_OAUTH_TOKEN"]
          log "WARNING: Skipping verification of Circle CI status because GitHub repo or OAuth token isn't set."

          return @app.call(env)
        end

        raise "A GitHub OAuth token is required to check the Circle CI status." unless ENV["GITHUB_OAUTH_TOKEN"]

        sha = latest_commit(env[:development_branch])

        uri = URI.parse("https://api.github.com/repos/#{env[:github_repo]}/statuses/#{sha}")

        connection = Net::HTTP.new(uri.host, uri.port)
        connection.use_ssl = true

        request = Net::HTTP::Get.new(uri.request_uri)
        request["Authorization"] = "token #{ENV["GITHUB_OAUTH_TOKEN"]}"
        response = connection.request(request)

        statuses = JSON.parse(response.body)

        if statuses.find { |s| s["state"] == "success" }
          # Success
        elsif status = statuses.find { |s| %w(failure error).include?(s["state"]) }
          raise "The Circle CI tests for branch '#{env[:development_branch]}' (commit #{sha}) failed. Fix them and try again. See #{status["target_url"]}"
        elsif status = statuses.find { |s| s["state"] == "pending"}
          raise "The Circle CI tests for branch '#{env[:development_branch]}' (commit #{sha}) are still running. Wait for them to finish successfully. See #{status["target_url"]}"
        else
          raise "The Circle CI tests for branch '#{env[:development_branch]}' (commit #{sha}) have not run yet. Wait for them to start and finish successfully."
        end

        @app.call(env)
      end
    end
  end
end