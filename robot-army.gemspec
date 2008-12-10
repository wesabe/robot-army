Gem::Specification.new do |s|
  s.name = %q{robot-army}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brian Donovan"]
  s.date = %q{2008-12-10}
  s.description = %q{Deploy using Thor by executing Ruby remotely}
  s.email = %q{brian@wesabe.com}
  s.extra_rdoc_files = ["README.markdown", "LICENSE"]
  s.files = ["LICENSE", "README.markdown", "Rakefile", "lib/robot-army", "lib/robot-army/connection.rb", "lib/robot-army/dependency_loader.rb", "lib/robot-army/gate_keeper.rb", "lib/robot-army/io.rb", "lib/robot-army/loader.rb", "lib/robot-army/marshal_ext.rb", "lib/robot-army/messenger.rb", "lib/robot-army/officer.rb", "lib/robot-army/officer_connection.rb", "lib/robot-army/officer_loader.rb", "lib/robot-army/proxy.rb", "lib/robot-army/ruby2ruby_ext.rb", "lib/robot-army/soldier.rb", "lib/robot-army/task_master.rb", "lib/robot-army.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/wesabe/robot-army}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{robot-army}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Deploy using Thor by executing Ruby remotely}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<ruby2ruby>, ["= 1.1.9"])
      s.add_runtime_dependency(%q<thor>, ["> 0.0.0"])
    else
      s.add_dependency(%q<ruby2ruby>, ["= 1.1.9"])
      s.add_dependency(%q<thor>, ["> 0.0.0"])
    end
  else
    s.add_dependency(%q<ruby2ruby>, ["= 1.1.9"])
    s.add_dependency(%q<thor>, ["> 0.0.0"])
  end
end
