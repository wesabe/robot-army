Robot Army
==========

Robot Army is deploy scripting which offers remote execution of Ruby in addition to the usual shell scripting offered by other deploy packages.

If you want to test this, be sure that the `robot-army` gem is installed on *both* the client and server machines. You should get an error if you try to execute it against a server with it installed.

Example
-------

    class AppServer < RobotArmy::TaskMaster
      host 'app1.prod.example.com'
      
      desc "time", "Get the time on the server (delta will be slightly off depending on SSH delay)"
      def time
        rtime = remote{ Time.now }
        ltime = Time.now
        
        say "The time on #{host} is #{rtime}, " +
            "#{(rtime-ltime).abs} seconds #{rtime < ltime ? 'behind' : 'ahead of'} localhost"
      end
      
      desc "deployed_revision", "Gets the deployed revision"
      def deployed_revision
        say "Checking deployed revision on #{host}"
        say "Deployed revision: #{remote{ File.read("/opt/app/current/REVISION") }}"
      end
    end

Known Issues
------------

  * No attempt is made to support `sudo` yet
  * Code executed in `remote` has no access to instance variables, globals, or methods on `self`
  * Multiple hosts are not yet supported
  * Probably doesn't work with Windows
