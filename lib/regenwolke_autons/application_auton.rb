require 'structure_mapper'
require 'socket'

module RegenwolkeAutons

  class CurrentDeployment
    include StructureMapper::Hash
    attribute git_sha1: String
    attribute host_ip: String
    attribute port: Fixnum
  end

  class ApplicationAuton < Nestene::Auton

    attribute application_name: String
    attribute host_matcher: String

    attribute current_deployment: CurrentDeployment

    attribute environment: {String => String}

    attr_accessor :context

    def start(application_name)
      self.environment = {}
      self.application_name = application_name
      if application_name.include?('.')
        if application_name.start_with?('www.')
          self.host_matcher = "(%s)|(%s)" % [application_name.gsub('.','\.'), application_name.gsub(/^www\./,'').gsub('.','\.')]
        else
          self.host_matcher = application_name.gsub('.','\.')
        end

      else
        self.host_matcher = application_name+'\..+'
      end
    end

    def deploy(git_sha1)
      deployment_name = "deployment:%s:%s" % [application_name, git_sha1]
      context.create_auton 'RegenwolkeAutons::DeploymentAuton', deployment_name
      context.schedule_step_on_auton deployment_name, :start, [application_name, git_sha1, environment]
    end

    def set_environment(values)
      self.environment.merge!(values)
      if current_deployment
        deployment_name = "deployment:%s:%s" % [application_name, current_deployment.git_sha1]
        context.schedule_step_on_auton deployment_name, :set_environment, [environment]
      end

    end


    def deployment_complete(git_sha1, host_ip, port)

      if current_deployment && current_deployment.git_sha1 != git_sha1
        deployment_name = "deployment:%s:%s" % [application_name, current_deployment.git_sha1]
        context.schedule_step_on_auton deployment_name, :terminate
      end

      self.current_deployment = CurrentDeployment.from_structure({
        'git_sha1' => git_sha1,
        'host_ip' => host_ip,
        'port' => port
      })

      context.schedule_step_on_auton('nginx', :update_application_configuration, [
        application_name,
        {
          'host_matcher' => host_matcher,
          'endpoints' => [
            {
              'hostname' => host_ip,
              'port' => port
            }
          ]
        }
      ])

    end

  end

end


