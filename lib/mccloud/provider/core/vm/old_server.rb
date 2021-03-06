require 'net/ssh/multi'
require 'pp'
module Mccloud
  module Command
    def server(selection=nil,options=nil)

      puts "Starting server mode"
      trap("INT") { puts "You've hit CTRL-C . Stopping server now"; exit }
      threads = []
      on_selected_machines(selection) do |id,vm|
        threads << Thread.new(id,vm) do |id,vm|
          public_ip_address=vm.instance.public_ip_address
          private_ip_address=vm.instance.private_ip_address
          unless public_ip_address.nil? || private_ip_address.nil?
            ssh_options={ :keys => [ vm.private_key ], :paranoid => false, :keys_only => true}
            Net::SSH.start(public_ip_address, vm.user, ssh_options) do |ssh|
              vm.forwardings.each do |forwarding|
                begin
                  puts "Forwarding remote port #{forwarding.remote} from #{vm.name} to local port #{forwarding.local}"
                  ssh.forward.local(forwarding.local, private_ip_address,forwarding.remote)
                rescue Errno::EACCES
                  puts "  Error - Access denied to forward remote port #{forwarding.remote} from #{vm.name} to local port #{forwarding.local}"
                end
              end
              ssh.loop { true }
            end
          end
        end
      end
      threads.each {|thr| thr.join}
      #puts "and we continue here"
      #sleep 30
    end
  end
end
