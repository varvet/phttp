require "bundler/gem_tasks"

task :console do
  exec "pry", "-Ilib", "-rphttp"
end

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new

task default: :spec
