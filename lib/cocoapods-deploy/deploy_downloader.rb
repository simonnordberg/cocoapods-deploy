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
      source.fetch(config.sandbox)
    end

    def download_podspec(config)
      dependencies_for_sources(config).each do |dep|
        source = ExternalSources.from_dependency(dep, config.podfile.defined_in_file)
        source.no_validate = true
        
        begin
          return source.fetch(config.sandbox)
        rescue Exception
          puts "Not Found"
        end
      end

      raise Informative, "Failed to deploy podspec for `#{@dependency.name}`."
    end

    def podfile_sources(config)
      return ["https://github.com/CocoaPods/Specs.git"] if config.podfile.sources.empty?
      return config.podfile.sources
    end

    def dependencies_for_sources(config)
      podfile_sources(config).map do |source|
        filename = File.basename(source, ".*")
        raw_url = File.join( File.dirname(source), filename )
        root_urls = [
          "#{raw_url}/raw/master/Specs",
          "#{raw_url}/raw/master"
        ]

        root_urls.map do |url|
          source = @dependency.external_source[:podspec].gsub('{root-url}', url)
          dependencies_for_url(source)
        end
      end.flatten
    end

    def dependencies_for_url(url)
      [
        Dependency.new(@dependency.name, {:podspec => "#{url}.podspec"}),
        Dependency.new(@dependency.name, {:podspec => "#{url}.podspec.json"})
      ]
    end
  end
end
