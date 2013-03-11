require "bundler/gem_tasks"
require 'cucumber'
require 'cucumber/rake/task'

desc "Build and Test"
task :default => [:build, :test]

Cucumber::Rake::Task.new(:test) do |t|
  t.cucumber_opts = "features --format pretty"
end
