require "takeoff/plan/base"

require "takeoff/stage/log"
require "takeoff/stage/look_out_for_danger"
require "takeoff/stage/stash_changes"
require "takeoff/stage/checkout_development_branch"
require "takeoff/stage/verify_github_up_to_date"
require "takeoff/stage/point_checkpoint_to_development"
require "takeoff/stage/push_to_github"

module Takeoff
  module Plan
    class Default < Base
      env.merge!(
        environment:        "production",
        github_remote:      "github",
        development_branch: "develop",
        checkpoint_branch:  "master"
      )
      
      stages do
        use Stage::Log
        use Stage::LookOutForDanger

        use Stage::StashChanges
        use Stage::CheckoutDevelopmentBranch
        
        use Stage::VerifyGithubUpToDate

        use Stage::PointCheckpointToDevelopment

        use Stage::PushToGithub
      end
    end
  end
end