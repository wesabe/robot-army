require File.dirname(__FILE__) + '/spec_helper'

# THIS SPEC IS INTENDED TO BE RUN BY ITSELF:
#
#   env SUDO_AS=brad INTEGRATION_HOST=example.com spec spec/integration_spec.rb --format=specdoc --color
#

if $INTEGRATION_HOST = ENV['INTEGRATION_HOST']
  $TESTING = false
  $ROBOT_ARMY_DEBUG = true

  class Integration < RobotArmy::TaskMaster
    host $INTEGRATION_HOST
  end

  describe Integration do
    before do
      @tm = Integration.new
    end

    it "can do sudo" do
      @tm.sudo { Time.now }.must be_a(Time)
    end

    it "does sudo as root by default" do
      @tm.sudo { Process.uid }.must == 0
    end

    it "can do sudo as ourselves" do
      my_remote_uid = @tm.remote { Process.uid }
      @tm.sudo(:user => ENV['donovan']) { Process.uid }.must == my_remote_uid
    end

    if sudo_user = ENV['SUDO_AS']
      it "can sudo as another non-root user" do
        @tm.sudo(:user => sudo_user) { ENV['USER'] }.must == sudo_user
      end
    end
  end
end
