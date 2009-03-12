class RobotArmy::Keychain
  def get_password_for_user_on_host(user, host)
    read_with_prompt("[sudo] password for #{user}@#{host}: ")
  end

  def read_with_prompt(prompt)
    require 'highline'
    HighLine.new.ask(prompt) {|q| q.echo = false}
  end
end
