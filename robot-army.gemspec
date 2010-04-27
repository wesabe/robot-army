# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Thorfile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{robot-army}
  s.version = "0.1.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brian Donovan"]
  s.date = %q{2010-04-26}
  s.description = %q{Deploy using Thor by executing Ruby remotely}
  s.email = %q{brian@wesabe.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.markdown"
  ]
  s.files = [
    "LICENSE",
     "README.markdown",
     "Rakefile",
     "lib/robot-army.rb",
     "lib/robot-army/at_exit.rb",
     "lib/robot-army/connection.rb",
     "lib/robot-army/dependency_loader.rb",
     "lib/robot-army/eval_builder.rb",
     "lib/robot-army/eval_command.rb",
     "lib/robot-army/gate_keeper.rb",
     "lib/robot-army/io.rb",
     "lib/robot-army/keychain.rb",
     "lib/robot-army/loader.rb",
     "lib/robot-army/marshal_ext.rb",
     "lib/robot-army/messenger.rb",
     "lib/robot-army/officer.rb",
     "lib/robot-army/officer_connection.rb",
     "lib/robot-army/officer_loader.rb",
     "lib/robot-army/proxy.rb",
     "lib/robot-army/remote_evaler.rb",
     "lib/robot-army/ruby2ruby_ext.rb",
     "lib/robot-army/soldier.rb",
     "lib/robot-army/task_master.rb"
  ]
  s.homepage = %q{http://github.com/wesabe/robot-army}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{robot-army}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Deploy using Thor by executing Ruby remotely}
  s.test_files = [
    "spec/at_exit_spec.rb",
     "spec/connection_spec.rb",
     "spec/dependency_loader_spec.rb",
     "spec/gate_keeper_spec.rb",
     "spec/integration_spec.rb",
     "spec/io_spec.rb",
     "spec/keychain_spec.rb",
     "spec/loader_spec.rb",
     "spec/marshal_ext_spec.rb",
     "spec/messenger_spec.rb",
     "spec/officer_spec.rb",
     "spec/proxy_spec.rb",
     "spec/ruby2ruby_ext_spec.rb",
     "spec/soldier_spec.rb",
     "spec/spec_helper.rb",
     "spec/task_master_spec.rb",
     "examples/whoami.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ParseTree>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<ruby2ruby>, [">= 1.2.0"])
      s.add_runtime_dependency(%q<thor>, [">= 0.11.7"])
    else
      s.add_dependency(%q<ParseTree>, [">= 3.0.0"])
      s.add_dependency(%q<ruby2ruby>, [">= 1.2.0"])
      s.add_dependency(%q<thor>, [">= 0.11.7"])
    end
  else
    s.add_dependency(%q<ParseTree>, [">= 3.0.0"])
    s.add_dependency(%q<ruby2ruby>, [">= 1.2.0"])
    s.add_dependency(%q<thor>, [">= 0.11.7"])
  end
end

