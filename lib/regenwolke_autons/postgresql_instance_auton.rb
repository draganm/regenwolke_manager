require 'docker'
require 'socket'
require 'securerandom'

module RegenwolkeAutons

  class PostgresqlInstanceAuton < Nestene::Auton

    POSTGRESQL_PORT = 5432

    attribute instance_name: String
    attribute username: String
    attribute password: String
    attribute server_ip: String
    attribute container_id: String
    attribute applications: [String]

    attr_accessor :context

    def start(name)
      self.instance_name = name
      context.schedule_step(:generate_credentials)
      context.schedule_step(:start_container)
      self.applications=[]
    end

    def generate_credentials
      self.username = SecureRandom.hex(8)
      self.password = SecureRandom.hex(12)
    end

    def start_container
      container = Docker::Container.create(
      'Image' => 'postgres:9.4.0',
      "Env" => [
        "POSTGRES_USER=#{self.username}",
        "POSTGRES_PASSWORD=#{self.password}"
      ],
      # "HostConfig" => {
      #   "Binds" => [
      #     "/regenwolke/capsules/#{self.application_name}-#{self.git_sha1}.tar:/app.tar:ro"
      #   ]
      # }
      )
      container.start
      self.container_id = container.id

      self.server_ip = container.json['NetworkSettings']['IPAddress']

    end

    def add_instance_to_application(application_name, primary_database)
      applications << application_name unless applications.include? application_name

      url = "postgres://#{username}:#{password}@#{server_ip}:#{POSTGRESQL_PORT}/#{username}"

      env = {"#{instance_name}_REGENWOLKE_POSTGRES_URL" => url}
      env.merge!("DATABASE_URL" => url) if primary_database

      context.schedule_step_on_auton application_auton_name(application_name), :set_environment, [env]
    end

    private

    def application_auton_name(application_name)
      'application:%s' % application_name
    end

  end

end
