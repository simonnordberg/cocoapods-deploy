module Pod
  class DeployDownloader

    attr_accessor :dependency

    def initialize(dependency)
      @dependency = dependency
    end

    def download(config)
      if @dependency.external_source.key?(:podspec)
        download_podspec(config)
      else
        download_source(config)
      end
    end

    #Download Normal
    def download_source(config)
      # TODO: Method for looping through dependency
      source = ExternalSources.from_dependency(dependency, config.podfile.defined_in_file)
      source.fetch(config.sandbox)
    end

    #Download Podspecs
    def download_podspec(config)
      # TODO: Method for looping through dependency
      source = ExternalSources.from_dependency(dependency, config.podfile.defined_in_file)
      source.fetch(config.sandbox)
    end
  end
end
