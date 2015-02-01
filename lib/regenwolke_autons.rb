require 'nestene'
require 'regenwolke_autons/regenwolke_auton'
require 'regenwolke_autons/application_auton'
require 'regenwolke_autons/deployment_auton'
require 'regenwolke_autons/nginx_auton'
require 'regenwolke_autons/postgresql_service_auton'
require "regenwolke_autons/version"


module RegenwolkeAutons

  class Core
    def self.init

      Dir.mkdir('regenwolke/nginx') unless File.exists?('regenwolke/nginx')
      Dir.mkdir('regenwolke/capsules') unless File.exists?('regenwolke/capsules')

      unless Celluloid::Actor[:nestene_core].auton_names.include?('nginx')
        Celluloid::Actor[:nestene_core].create_auton('RegenwolkeAutons::RegenwolkeAuton','regenwolke')
        Celluloid::Actor[:nestene_core].schedule_step('regenwolke', 'start')
      end
    end
  end

end
