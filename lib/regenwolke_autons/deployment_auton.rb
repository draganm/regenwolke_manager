require 'docker'
require 'socket'

module RegenwolkeAutons

  class DeploymentAuton < Nestene::Auton

    attribute application_name: String
    attribute git_sha1: String
    attribute host_ip: String
    attribute container_id: String

    attr_accessor :context

    def start(application_name, git_sha1)
      self.application_name = application_name
      self.git_sha1 = git_sha1
      context.schedule_step(:start_container)
    end

    def start_container
      # TODO extract creation of container config to a method and thorroughly test it
      container = Docker::Container.create(
        'Image' => 'dmilhdef/buildstep',
        'Cmd' => [
          '/bin/bash',
          '-c',
          'useradd runner && cd / && tar xf /app.tar && /start web'
        ],
        "Env" => [
          "PORT=5000"
        ],
        "ExposedPorts" => {
          "5000/tcp" => {}
        },
        "HostConfig" => {
          "Binds" => [
            "/regenwolke/capsules/#{self.application_name}-#{self.git_sha1}.tar:/app.tar:ro"
          ]
        }
      )
      container.start
      self.container_id = container.id
      
      self.host_ip = container.json['NetworkSettings']['IPAddress']
      context.schedule_step(:wait_for_container_to_start)
    end

    def wait_for_container_to_start(retries = 0)

      if retries > 9
        raise "could not start after 9 retries"
      end

      if endpoint_responding?
        context.schedule_step(:notify_application)
      else
        context.schedule_delayed_step 3, :wait_for_container_to_start, [retries + 1]
      end
    end

    def notify_application
      application_auton_id = "application:%s" % application_name
      context.schedule_step_on_auton(application_auton_id, :deployment_complete, [self.git_sha1, self.host_ip, 5000])
    end

    def terminate
      container = Docker::Container.get(self.container_id)
      container.delete(:force => true)
      context.terminate
    end


    private

    def endpoint_responding?
      socket = TCPSocket.new host_ip, 5000
      socket.write "GET / HTTP/1.0\r\n"
      socket.write "\r\n"
      line = socket.readline
      status = line.split(' ')[1]
      ['2', '3','4','1'].include? status[0]
    rescue Errno::ECONNREFUSED => e
      false
    end


  end

end


