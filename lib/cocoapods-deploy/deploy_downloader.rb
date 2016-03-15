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
      source = ExternalSources.from_dependency(dependency, config.podfile.defined_in_file)
      source.fetch
    end

    def download_podspec(config)
      dependencies_for_sources(config).each do |dep|
        puts "woo #{dep}"
        source = ExternalSources.from_dependency(dep, config.podfile.defined_in_file)
        source.fetch
      end
    end

    def podfile_sources(config)
      return ["https://github.com/CocoaPods/CocoaPods.git"] if config.podfile.sources.empty?
      return config.podfile.sources
    end

    def dependencies_for_sources(config)
      podfile_sources(config).map do |source|
        filename = File.basename(source, ".*")
        raw_url = File.join( File.dirname(source), filename )
        root_url = "#{raw_url}/raw"
        source = @dependency.external_source[:podspec].gsub('{root-url}', root_url)

        Dependency.new(@dependency.name, {:podspec => source})
      end
    end
  end
end
