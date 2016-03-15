module Pod
  class DeployDownloader

    attr_accessor :dependency

    def initialize(dependency)
      @dependency = dependency
    end

    def download(config)
      # TODO: Method for looping through dependency
      #source = ExternalSources.from_dependency(dependency, config.podfile.defined_in_file)
      #source.fetch(config.sandbox)
    end
  end
end
