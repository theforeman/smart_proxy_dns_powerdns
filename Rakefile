require 'rake'
require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => :test
task :test => "test:unit"

desc 'Test the Foreman Proxy plugin.'
namespace :test do
  desc "Run all tests"
  Rake::TestTask.new(:all) do |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.test_files = FileList['test/**/*_test.rb']
    t.verbose = true
  end

  desc "Run unit tests"
  Rake::TestTask.new(:unit) do |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.test_files = FileList['test/unit/**/*_test.rb']
    t.verbose = true
  end

  desc "Run integration tests"
  Rake::TestTask.new(:integration) do |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.test_files = FileList['test/integration/**/*_test.rb']
    t.verbose = true
  end
end
