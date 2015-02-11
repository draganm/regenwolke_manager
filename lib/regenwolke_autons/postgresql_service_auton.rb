require 'docker'
require 'socket'

module RegenwolkeAutons

  class PostgresqlServiceAuton < Nestene::Auton

    attribute instances: {String => String}

    attr_accessor :context

    def initialize
      self.instances = {}
    end

    def start
    end

    def create_instance instance_name

      unless instances.has_key?(instance_name)
        auton_name = "postgresql:%s" % instance_name
        self.instances[instance_name] = auton_name
        context.create_auton("RegenwolkeAutons::PostgresqlInstanceAuton", auton_name)
        context.schedule_step_on_auton(auton_name, :start, [instance_name])
      end

    end

    def add_instance_to_application instance_name, application_name, primary_database
      if instances.has_key?(instance_name)
        context.schedule_step_on_auton instances[instance_name], :add_instance_to_application, [application_name, primary_database]
      end

    end

  end

end


