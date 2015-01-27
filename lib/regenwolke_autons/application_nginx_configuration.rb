require 'regenwolke_autons/application_endpoint'

module RegenwolkeAutons

  class ApplicationNginxConfiguration

    include StructureMapper::Hash

    attribute host_matcher: String
    attribute endpoints: [ApplicationEndpoint]
  end

end