#--*-- encoding: UTF-8 --*--
require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "overridable"
    gem.summary = %Q{Override methods without method alias.}
    gem.description = %Q{Overridable is a pure ruby library which helps you to make your methods which are defined in classes to be able to be overrided by mixed-in modules.}
    gem.email = "liang.gimi@gmail.com"
    gem.homepage = "http://github.com/Gimi/overridable"
    gem.authors = ["梁智敏(Gimi Liang)"]
    gem.add_development_dependency "riot", ">= 0.10.0"
    gem.add_development_dependency "yard", ">= 0.4.0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
