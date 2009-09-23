require 'thor/rake_compat'
require 'spec/rake/spectask'

GEM = "robot-army"

class Default < Thor
  include Thor::RakeCompat

  Spec::Rake::SpecTask.new(:spec) do |t|
    t.libs << 'lib'
    # t.spec_opts = ['--options', 'spec/spec.opts']
    t.spec_files = FileList['spec/**/*_spec.rb']
  end

  Spec::Rake::SpecTask.new(:rcov) do |t|
    t.libs << 'lib'
    # t.spec_opts = ['--options', 'spec/spec.opts']
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.rcov = true
    t.rcov_dir = 'rcov'
  end

  begin
    require 'jeweler'
    Jeweler::Tasks.new do |s|
      s.name = GEM
      s.rubyforge_project = 'robot-army'
      s.platform = Gem::Platform::RUBY
      s.summary = "Deploy using Thor by executing Ruby remotely"
      s.email = "brian@wesabe.com"
      s.homepage = "http://github.com/wesabe/robot-army"
      s.description = "Deploy using Thor by executing Ruby remotely"
      s.authors = ['Brian Donovan']
      s.require_path = 'lib'
      s.bindir = 'bin'
      s.files = %w(LICENSE README.markdown Rakefile) + Dir.glob("{bin,lib,specs}/**/*")
      s.add_dependency("ParseTree", [">= 3.0.0"])
      s.add_dependency("ruby2ruby", [">= 1.2.0"])
      s.add_dependency("thor", [">= 0.11.7"])
    end
  rescue LoadError
    puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
  end
end
