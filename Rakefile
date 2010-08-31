require 'rubygems'
require 'rake'
require 'yaml'
require 'cucumber/rake/task'
require 'spec/rake/spectask'

task :default => :test
task :test => :spec

if !defined?(Spec)
  puts "spec targets require RSpec"
else
  desc "Run all examples"
  Spec::Rake::SpecTask.new('spec') do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts = ['-cfs']
  end
end

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = %w{--format pretty}
end

namespace :gems do
  desc 'Install required gems'
  task :install do
    required_gems = %w{ sinatra twitter_oauth oauth addressable fakeweb mocha twilio active_support active_record }
    required_gems.each { |required_gem| system "sudo gem install #{required_gem}" }
  end
end
