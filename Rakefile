# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

namespace :test do  
  Rake::TestTask.new(:business => "db:test:prepare") do |t|
    t.libs << "test"
    t.pattern = 'business/test/**/*_test.rb'
    t.verbose = true
  end
  Rake::Task['test:business'].comment = "Run all business tests"
end

desc 'Run all business, unit, functional and integration tests'
task :test do
  errors = %w(test:units test:functionals test:integration).collect do |task|
    begin
      Rake::Task[task].invoke
      nil
    rescue => e
      task
    end
  end.compact
  abort "Errors running #{errors.to_sentence(:locale => :en)}!" if errors.any?
end

require 'tasks/rails'
