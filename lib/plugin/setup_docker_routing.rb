
require 'open3'
def syscall(log, cmd)
  print "#{log} ... "
  status = nil
  Open3.popen2e(cmd) do |input, output, thr|
    output.each {|line| puts line }
    status = thr.value
  end
  if status.success?
    puts "done"
  else
    exit(1)
  end
end

class SetupDockerRouting < Vagrant.plugin('2')
  name 'setup_docker_routing'

  class Action
    def initialize(app, env)
      @app = app
    end

    def call(env)
      @app.call(env)

      syscall("** Setting up routing to .docker domain and NFS mount", <<-EOF
        bash ./bin/mount_nfs_share.sh
        EOF
      )
    end
  end

  action_hook(:setup_docker_routing, :machine_action_up) do |hook|
    hook.prepend(SetupDockerRouting::Action)
  end
end

