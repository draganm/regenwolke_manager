require 'structure_mapper'
require 'socket'
require 'regenwolke_autons/application_nginx_configuration'

module RegenwolkeAutons


  class NginxAuton < Nestene::Auton

    attribute configurations: {String => ApplicationNginxConfiguration}
    attribute stderr: String

    attr_accessor :context

    def initialize
      set_initial_configurations
    end

    def start
      context.schedule_step(:start_nginx_if_not_running)
      context.schedule_repeating_delayed_step 90, 90, :start_nginx_if_not_running
      set_initial_configurations
    end

    def start_nginx
      create_and_save_config
      check_current_config
      start_nginx_process
      wait_for_nginx
    end

    def update_application_configuration application_name, new_configuration
      if Hash === new_configuration
        new_configuration = ApplicationNginxConfiguration.from_structure(new_configuration)
      end
      self.configurations[application_name] = new_configuration
      context.schedule_step(:reconfigure_nginx)
    end


    def reconfigure_nginx
      create_and_save_config
      check_current_config
      reload_nginx_config
    end

    def start_nginx_if_not_running
      context.schedule_step(:start_nginx) unless nginx_running?
    end

    private


    def set_initial_configurations

      self.configurations = {
        'regenwolke' => ApplicationNginxConfiguration.from_structure({
          'host_matcher' => 'regenwolke\..+',
          'endpoints' => [
            {
              'hostname' => 'localhost',
              'port' => ENV['PORT'] || 5000
            }

          ]
        })
      }
    end

    def reload_nginx_config
      system('nginx','-p', 'regenwolke/nginx', '-c', 'nginx.config', '-s', 'reload') || raise("Could not reload nginx config")
    end

    def start_nginx_process
      system('nginx','-p', 'regenwolke/nginx', '-c', 'nginx.config') || raise("Could not start nginx")
    end

    def check_current_config
      system('nginx','-t','-p', 'regenwolke/nginx', '-c', 'nginx.config') || raise("Invalid nginx config")
    end

    def nginx_running?
      socket = TCPSocket.new "localhost", 9080
      socket.close
      true
    rescue Errno::ECONNREFUSED
      false
    end

    def wait_for_nginx
      (1..20).each do
        return if nginx_running?
        sleep 0.1
      end
      raise "nginx didn't start within 20 seconds"
    end

    def create_and_save_config
      config = create_config
      File.write("regenwolke/nginx/nginx.config",config)
    end

    def create_config
      erb = ERB.new File.read(File.expand_path('../nginx_config.erb', __FILE__))
      erb.result(binding)
    end

  end

end


