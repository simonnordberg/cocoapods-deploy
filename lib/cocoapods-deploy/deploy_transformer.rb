module Pod
  class DeployTransformer

    attr_accessor :lockfile

    def initialize(lockfile)
      @lockfile = lockfile
    end

    def transform_podfile(podfile)
      internal_hash = podfile.to_hash
      transform_internal_hash(internal_hash)

      Podfile.from_hash(internal_hash, podfile.defined_in_file)
    end

    private

    def transform_internal_hash(hash)
      hash["target_definitions"].map do |target|
        transform_target_definition_hash(target)
      end
    end

    def transform_target_definition_hash(hash)
      dependencies = hash["dependencies"]
      dependencies.map do |dep|
        transform_dependency(dep)
      end if dependencies

      children = hash["children"]
      children.map do |target|
        transform_target_definition_hash(target)
      end if children
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

        pod = dependency.name
        version = @lockfile.version(pod)
        raise "Missing dependency in Lockfile please run `pod install` or `pod update`." unless version

        { pod => [{ :podspec => podspec_url(pod, version) }] }
        # - If Repo transform to podspec url for version cross-referenced against
        # lockfile
        # - Check dependencies for podspecs if they are a subspec and include those
        # and version lock to their parent spec.
        # - If repo based pod or subspec not found in lockfile then abort.
      else
        # - If external leave it be
        name_or_hash
      end
    end
  end
end


#
# #Hack to help transform target dependencies
# class DeployTransformer
#
#   def self.lockfile=(lockfile)
#     @@lockfile = lockfile
#   end
#
#   #TODO: Remove Workaround resolver trying to pull down invalid pods
#   def self.in_lockfile(dep)
#     @@lockfile.pod_names.include? dep.root_name
#   end
#
#   #TODO: Remove lockfile modifications
#   def self.transform_dependency_to_sandbox_podspec(dep)
#     unless dep.external_source
#       version = @@lockfile.version(dep)
#       checkout = { :podspec => podspec_url(dep.root_name, version) }
#       dep.external_source = checkout
#       dep.requirement = Requirement.create(checkout)
#     end
#
#     dep
#   end
#
#   #TODO: Provide cleaner way of doing this in the future
#   def self.inject_subspec_dependencies
#    @@lockfile.to_hash["PODS"].select { |dep|
#      dep.is_a?(Hash)
#    }.map { |dep|
#      dep.values.first.map { |pod|
#        pod = pod.split(" ").first
#        parent = dep.keys.first.split(" ").first
#        version = @@lockfile.version(parent)
#        depen = Dependency.new(pod, version) #Get pod version
#        transform_dependency_to_sandbox_podspec(depen)
#      }
#    }.flatten
#   end
# end


#
# #TODO: Remove Hack to transform podfile dependencies to podspec ones - we should find
# #a way of removing some of these
# def apply_dependency_patches
#
#   DeployTransformer.lockfile = config.lockfile
#
#   Specification.class_eval do
#
#     alias_method :original_all_dependencies, :all_dependencies
#
#     def all_dependencies(platform = nil)
#       new_deps = original_all_dependencies.map do |dep|
#
#         unless dep.external_source
#           DeployTransformer.transform_dependency_to_sandbox_podspec(dep)
#         else
#           dep
#         end
#       end + DeployTransformer.inject_subspec_dependencies
#
#       new_deps.select do |dep|
#         DeployTransformer.in_lockfile(dep)
#       end
#     end
#   end
#
#   Resolver.class_eval do
#
#     alias_method :original_locked_dependencies, :locked_dependencies
#
#     def dependencies
#       new_deps = original_locked_dependencies.map do |dep|
#         unless dep.external_source
#           DeployTransformer.transform_dependency_to_sandbox_podspec(dep)
#         else
#           dep
#         end
#       end + DeployTransformer.inject_subspec_dependencies
#
#       new_deps.select do |dep|
#         DeployTransformer.in_lockfile(dep)
#       end
#     end
#   end
#
#   Podfile::TargetDefinition.class_eval do
#
#     alias_method :original_dependencies, :dependencies
#
#     def dependencies
#       new_deps = original_dependencies.map do |dep|
#         unless dep.external_source
#           DeployTransformer.transform_dependency_to_sandbox_podspec(dep)
#         else
#           dep
#         end
#       end + DeployTransformer.inject_subspec_dependencies
#
#       new_deps.select do |dep|
#         DeployTransformer.in_lockfile(dep)
#       end
#     end
#   end
# end

# def transform_dependency_and_version_to_remote_podspec(dep, version)
#   unless dep.external_source
#     checkout = { :podspec => podspec_url(dep.root_name, version) }
#     dep.external_source = checkout
#     dep.specific_version = nil
#     dep.requirement = Requirement.create(checkout)
#   end
#
#   dep
# end
#
# def dependency_for_pod_and_version(pod, version)
#   dep = config.lockfile.dependencies.detect { |d| d.root_name == pod }
#
#   unless dep
#     dep = Dependency.new(pod, version)
#   end
#
#   dep
# end
#
# def download_dependency(dep)
#   source = ExternalSources.from_dependency(dep, config.podfile.defined_in_file)
#   source.fetch(config.sandbox)
# end
#
# def transform_pod_and_version(pod, version)
#   dep = dependency_for_pod_and_version(pod, version)
#   transform_dependency_and_version_to_remote_podspec(dep, version)
#   download_dependency(dep)
# end
