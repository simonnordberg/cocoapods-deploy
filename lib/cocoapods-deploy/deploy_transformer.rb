module Pod
  class DeployTransformer

    attr_accessor :lockfile

    def initialize(lockfile)
      @lockfile = lockfile
    end

    def transform_podfile(podfile)
      internal_hash = podfile.to_hash
      new_hash = transform_internal_hash(internal_hash)

      Podfile.from_hash(new_hash, podfile.defined_in_file)
    end

    private

    def transform_internal_hash(hash)
      targets = hash["target_definitions"]
      targets.map do |target|
        transform_target_definition_hash(target)
      end if targets

      hash
    end

    def transform_target_definition_hash(hash)
      dependencies = hash["dependencies"]
      hash["dependencies"] = dependencies.map do |dep|
        transform_dependency(dep)
      end if dependencies

      children = hash["children"]
      hash["children"] = children.map do |target|
        transform_target_definition_hash(target)
      end if children

      hash
    end

    def parse_dependency(name_or_hash)
      if name_or_hash.is_a?(Hash)
        name = name_or_hash.keys.first
        requirements = name_or_hash.values.first
        Dependency.new(name, *requirements)
      else
        Dependency.new(name_or_hash)
      end
    end

    def podspec_url(pod, version)
      "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/#{pod}/#{version}/#{pod}.podspec.json"
    end

    def transform_dependency(name_or_hash)
      dependency = parse_dependency(name_or_hash)

      unless dependency.external_source

        root_pod = dependency.root_name
        pod = dependency.name
        version = @lockfile.version(pod)
        raise "Missing dependency in Lockfile please run `pod install` or `pod update`." unless version

        # - Check dependencies for Podspecs if they are a subspec and include them
        #   and version lock them to their parent spec.
        ({ "#{pod}" => [{ :podspec => podspec_url(root_pod, version) }] })
      else
        name_or_hash
      end
    end
  end
end
