require 'bundler/gem_tasks'
require 'rake/testtask'

desc "Run specs"
Rake::TestTask.new do |t|
    t.libs << "spec"
    t.pattern = "spec/**/*_spec.rb"
end

desc "Run specs (default)"
task :default => :test

desc "Remove protobuf definitions that have been compiled"
task :clean do
  FileUtils.rm(Dir.glob("spec/support/protobuf/**/*.proto"))
  puts "Cleaned"
end

desc "Compile spec/support protobuf definitions"
task :compile, [] => :clean do
  cmd = "rprotoc --ruby_out=spec/support/protobuf --proto_path=spec/support/definitions spec/support/definitions/*.proto"
  sh(cmd)
end
