# <img src="https://assets-cdn.github.com/images/icons/emoji/unicode/1f680.png" height="32" width="32" alt="🚀" /> Takeoff

#### Sit back, relax and let Takeoff deploy your app.

Takeoff is a command line tool that helps you deploy your web applications. Configure it once, and from then on Takeoff will take care of responsibly deploying your app, giving you time to <del>[practice your swordfighting](http://xkcd.com/303/)</del> <del>catch up on sleep</del> get more coffee. 

Takeoff was built with Git, Ruby, Rails and Heroku in mind, but is ultimately SCM, language, framework and hosting platform agnostic—it all comes down to how you configure it.

Takeoff is built around the concepts of **launch plans** and **stages**. 

Each Takeoff launch plan describes a particular type of deployment (launch), divided up into bite-sized steps (stages) that together make up the launch. Since you'd want to deploy to at least one server, every app has at least one launch plan, consisting of at least one stage: the actual "push to server".

Different launch plans can be used for different hosting platforms and ways of pushing (Git-based like Heroku, SSH-based like any regular VPS, or FTP-based like cheap PHP hosts) and for the different environments your app can work in (production, staging, etc.). In each of these cases, you'd use different (or differently configured) stages, tailored to the specifics of the launch you're doing.
 
Out of the box, Takeoff comes with a bare bones default launch plan as well as one adapted to Heroku, but you can easily create your own by picking and choosing from the different stages already included or if you so wish, by building your own.

## Installation

(Not convinced yet? Continue to [Configuration](#configuration) and read on.)

Takeoff can be added to your Ruby application by adding the following to your Gemfile and running `bundle install`:

```ruby
gem "takeoff", require: false, group: :development
```

To use Takeoff with a non-Ruby project or one without a Gemfile, install it from the command line:

```sh
gem install takeoff
```

## Configuration

A launch plan's stages are defined using the Middleware pattern popularized by Rack and Rails. Takeoff stages explicitly hand over control to the next stage in the launch plan and are given back control after that stage has finished, which means they can have effect both before and after all stages "down stream" have run. As an example, this allows you to plan a "maintenance mode" stage before the final "push to server" stage, which will enable maintenance mode, hand over control, wait for pushing to finish, get back control and finally disable maintenance mode, all from the one stage definition. 

In terms of code, a stage is a class with the following layout, which should look familiar if you've ever written Rails middleware:

```ruby
require "takeoff/stage/base"

class MyStage < Takeoff::Stage::Base
  def call(env)
    # `env` is a hash containing information about the the current launch. 
    # You can write to it if you think you have something stages downstream might
    # be interested in, or read from it if you're interested in info added upstream.

    # Here, you can do things before the next stage runs.

    # This call hands over control to the next stage in line, represented by @app
    # which is set by the inherited `Takeoff::Stage::Base#initialize`.
    @app.call(env)

    # Here, you can do things after the stage and all stages following it have run.

    # If you want to ensure the code to be run after is even run if any of the 
    # following stages raises an error, you can wrap `@app.call(env)` and the code 
    # to be run after in a begin/ensure/end block.
  end
end
```

The default launch plan (aptly named `:default`) is very bare bones. It's made up off the following stages:

```ruby
# Logs "Ready for takeoff!" before and "Takeoff (un)successful." after.
use Stage::Log

# Checks if there are any dangerous stages (like an unsafe migration) that 
# other stages might want to put up protection for (like a maintenance mode window).
# Adds arrays `:stages`, `:dangerous_stages` and boolean `:dangerous` to the env hash.
use Stage::LookOutForDanger

# Stashes uncommitted changes so Takeoff can safely move between branches.
use Stage::StashChanges

# Checks out the development branch with the code to be deployed.
use Stage::CheckoutDevelopmentBranch

# Verifies the development branch has been pushed to GitHub.
use Stage::VerifyGithubUpToDate

# Updates the deployment checkpoint branch to point to the development branch.
use Stage::PointCheckpointToDevelopment

# Pushes the deployment checkpoint branch to GitHub.
use Stage::PushToGithub
```

As you can see, this launch plan is missing an actual "push to server" or deploy stage. This is because this part of the launch plan is very setup-specific and without a default solution. You can configure the non-default stages of your launch plan in your Takeoff configuration file, which we'll get to in a moment.

Out of the box, Takeoff comes with a launch plan for Heroku (called `:heroku`), which adds onto `:default` as you can see below. Even if you're not on Heroku, this is interesting to read as you'll want to configure your own launch plans in a similar fashion.

```ruby
# Adds `:deployed_commit` and `:new_commit` to the env hash, so that other stages 
# can reference and use them.
insert_after Stage::Log,
  Stage::Heroku::RememberCommits

# Verifies the Heroku server isn't already up to date with the commit to be deployed.
insert_after Stage::VerifyGithubUpToDate, 
  Stage::Heroku::VerifyServerNotAlreadyUpToDate

insert_after Stage::PointCheckpointToDevelopment, [
  # Disables Heroku preboot if this is a dangerous deploy
  # according to `env[:dangerous]`, set by `LookOutForDanger`.
  Stage::Heroku::DisablePreboot,

  # Scales down Heroku workers if this is a dangerous deploy.
  Stage::Heroku::ScaleDownWorkers,

  # Enables Heroku maintenance mode if this is a dangerous deploy.
  Stage::Heroku::EnableMaintenanceMode,

  # Pushes deployment checkpoint branch to Heroku.
  Stage::Heroku::PushToServer,

  # Runs database migrations on Heroku if any are in the diff. 
  # This makes this deploy a dangerous one, which `LookOutForDanger` will pick up on 
  # and which `DisablePreboot`, `ScaleDownWorkers` and `EnableMaintenanceMode` 
  # will put up appropriate protection for.
  Stage::Heroku::MigrateDatabase
]
```

If you're on Heroku, chances are this `:heroku` launch plan is exactly what you're looking for. In your configuration file, you can configure Takeoff to use the `:heroku` plan by default, instead of the plan _named_ `:default`, which, as mentioned, does very little.

Takeoff loads configuration from either `./Launchfile` or `./config/takeoff.rb` by default, relative from your project directory, so use whichever you prefer. If neither is to your liking, you can override the config file location when you run `takeoff`. 

Let's set `:heroku` as the default plan:

```rb
require "takeoff/plan/heroku"

default_plan :heroku

# By default, the Heroku launch plan looks for these Git branches and remotes,
# as specified in its default env hash. If any of these are different for you, 
# you can override them from here—your configuration file.
# env.merge!(
#   # The Rails/Rack environment you're deploying to.
#   environment:        "production",
#
#   # The Git remote that points to your GitHub repo.
#   github_remote:      "github",
#
#   # The branch that you want deployed, typically the branch you develop in.
#   development_branch: "develop",
#
#   # The branch that functions as a checkpoint for commits deployed to the server.
#   checkpoint_branch:  "master",
#
#   # The Git remote that points to your Heroku app.
#   server_remote:      "heroku"
# )
```

If you deploy to multiple servers (as you should), you'll want to create different launch plans with different a env configuration for each of them:

```rb
require "takeoff/plan/heroku"

require "takeoff/stage/heroku/verify_staging_up_to_date"

default_plan :heroku

# New plans are based on the default plan, `:heroku` in our case.
plan :staging do
  # We want to override the Heroku env defaults listed above.
  env.merge!(
    environment:        "staging",
    checkpoint_branch:  "staging",
    server_remote:      "staging"
  )
end

# You can override the parent plan by adding a `:based_on` option.
# Instead of `default_plan :heroku`, we could also have used `based_on: :heroku` 
# above, to explicitly base `:staging` off of that.
plan :production, based_on: :staging do
  # These first two are the defaults for the `:heroku` plan, but since we're based 
  # on `:staging` we need to reset them to those defaults.
  env.merge!(
    environment:        "production",
    checkpoint_branch:  "master",
    server_remote:      "production"
  )

  # Your new launch plan can add stages if you so wish. The one below is included 
  # with Takeoff but is not part of either the default or Heroku launch plans.
  # It verifies that the staging server is up to date before deploying to production.
  # To know where to check, it requires a Heroku-based launch plan called `:staging`.
  stages do
    insert_before Takeoff::Stage::VerifyServerNotAlreadyUpToDate, 
      Takeoff::Stage::Heroku::VerifyStagingUpToDate
  end
end

# Because we don't want a plain `takeoff launch` command to use the unconfigured
# `:heroku` plan, we set `:staging` to be the default.
default_plan :staging
```

Other stages included with Takeoff that are not part of either the default or Heroku launch plans, are `Takeoff::Stage::VerifyCircleCiStatus` and `Takeoff::Stage::Heroku::PrecompileAndSyncAssets`. The former verifies that the commit to be pushed has been tested successfully on [Circle CI](http://circleci.com); the latter precompiles Rails assets and syncs them to Amazon S3 using the [AssetSync](https://github.com/rumblelabs/asset_sync) gem. Both would typically be inserted before `Takeoff::Stage::PointCheckpointToDevelopment`, which is itself before the "push to server" stage.

To see an example of an actual production Launchfile, namely the one we use to deploy [Stinngo](https://www.stinngo.com), check out [`example.Launchfile`](example.Launchfile).

## Usage

To let Takeoff deploy your app, use the `takeoff` command on the command line, like so:

```sh
takeoff [launch [PLAN]] [--config CONFIG] [--skip SKIP]
```

- `PLAN` can be any launch plan that comes out of the box or that you've specified in your configuration file. `PLAN` defaults to the contents of the `RACK_ENV` or `RAILS_ENV` environment variable or the default plan set in your configuration file.
- `CONFIG`: Path to your Takeoff configuration file. Defaults to `./Launchfile` or `./config/takeoff.rb`.
- `SKIP`: Space-seperated list of full or partial names of stages to skip. Example: `-s VerifyServerNotAlreadyUpToDate` if you want to re-do a deployment.

For the best result, Takeoff should be run in a terminal simulator that supports Emoji, like OS X's Terminal.app. However, as long as your terminal app doesn't break when it comes across Emoji, it's no big deal if it doesn't actually render the images.

## Attribution

Takeoff was built at [Stinngo](http://www.stinngo.com) by [Douwe Maan](http://github.com/DouweM), who was unhappy with the hacked-together deploy scripts they had been using before and wanted to settle the matter once and for all.

Takeoff took inspiration from [envato/heroku-deploy](https://github.com/envato/heroku-deploy), [mattpolito/paratrooper](https://github.com/mattpolito/paratrooper) and numerous `deploy.sh` scripts and `rake deploy` tasks floating around the web.

## To Do

Takeoff has been in use at Stinngo for a while now, but we realize there's still work to be done to make it a viable option for everyone. Hence, this to do list:

- [ ] Properly handle "first deploy", when the expected Heroku app, remote and checkpoint branches don't exist or are empty.
- [ ] Do all of the Git-shuffling in a seperate (temporary) folderm so you can keep working in your development one while Takeoff is deploying.
- [ ] Add more out of the box launch plans and stages: 
    - [ ] SSH push
    - [ ] FTP push
    - [ ] generic Git push
    - [ ] Rails assets precompilation without S3 sync
- [ ] Colorize log messages.
- [ ] Raise nicer error when command fails.
- [ ] Add banner?

If you like Takeoff, feel free to pick any one of these up—I'll gladly accept pull requests.

## License

    Copyright (c) 2014 Douwe Maan

    MIT License

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.