module RegenwolkeAutons
  class ApplicationEndpoint
    include StructureMapper::Hash

    attribute hostname: String
    attribute port: Fixnum
  end
end