require 'structure_mapper'

module RegenwolkeAutons

  class RegenwolkeAuton < Nestene::Auton
    attribute applications: [String]


    attr_accessor :context

    def initialize
      self.applications = []
    end

    def start
      context.create_auton('RegenwolkeAutons::NginxAuton', 'nginx')
      context.schedule_step_on_auton('nginx', :start)
      context.create_auton('RegenwolkeAutons::PostgresqlServiceAuton', 'postgresql_service')
      context.schedule_step_on_auton('postgresql_service', :start)
    end

    def deploy_application(name, git_sha1)

      unless applications.include?(name)
        context.create_auton 'RegenwolkeAutons::ApplicationAuton', application_auton_name(name)
        context.schedule_step_on_auton application_auton_name(name), :start, [name]
        self.applications << name
      end

      context.schedule_step_on_auton(application_auton_name(name),:deploy,[git_sha1])

    end


    private

    def application_auton_name(application_name)
      'application:%s' % application_name
    end

  end

end


