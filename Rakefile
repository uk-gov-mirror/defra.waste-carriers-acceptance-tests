# frozen_string_literal: true

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: :run

# Remember to create an environment variable in Travis (can be set to anything)!
if ENV["TRAVIS"]
  # Setting the default is additive. So if we didn't add the following line
  # :default would now run both all tests and rubocop
  Rake::Task[:default].clear
  task default: [:ci]
end

desc "Run all scenarios (eq to bundle exec quke)"
task :run do
  sh %( bundle exec quke )
end

desc "Run all work in progress scenarios"
task :wip do
  sh %( QUKE_CONFIG=.config_galaxyS8.yml bundle exec quke --tags @wip)
end

desc "Runs the tests used by continuous integration to check the project"
task :ci do
  Rake::Task["rubocop"].invoke
  sh %( QUKE_CONFIG=.config-ci.yml bundle exec quke --tags @ci )
end
