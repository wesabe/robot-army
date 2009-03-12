require File.dirname(__FILE__) + '/spec_helper'

describe RobotArmy::Keychain do
  before do
    @keychain = RobotArmy::Keychain.new
  end

  it "asks for all passwords over stdin" do
    @keychain.
      should_receive(:read_with_prompt).
      with("[sudo] password for bob@example.com: ").
      and_return("god")
    @keychain.get_password_for_user_on_host('bob', 'example.com').must == 'god'
  end
end
