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

    def download_source(config)
      # TODO: Method for looping through dependency
      source = ExternalSources.from_dependency(dependency, config.podfile.defined_in_file)
      source.fetch(config.sandbox)
    end

    def download_podspec(config)
      dependencies_for_sources(config).each do |dep|
        source = ExternalSources.from_dependency(dep, config.podfile.defined_in_file)
        source.fetch(config.sandbox)
      end
    end

    private

    def dependencies_for_sources(config)
      []
    end
  end
end
