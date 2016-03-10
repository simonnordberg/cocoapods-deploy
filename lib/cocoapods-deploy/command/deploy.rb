def podspec_url(pod, version)
  "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/#{pod}/#{version}/#{pod}.podspec.json"
end

module Pod
  class Command

    #Hack to help transform target dependencies
    class DeployTransformer

      def self.lockfile=(lockfile)
        @@lockfile = lockfile
      end

      #TODO: Remove Workaround resolver trying to pull down invalid pods
      def self.in_lockfile(dep)
        @@lockfile.pod_names.include? dep.root_name
      end

      #TODO: Remove lockfile modifications
      def self.transform_dependency_to_sandbox_podspec(dep)
        unless dep.external_source
          version = @@lockfile.version(dep)
          checkout = { :podspec => podspec_url(dep.root_name, version) }
          dep.external_source = checkout
          dep.requirement = Requirement.create(checkout)
        end

        dep
      end

      #TODO: Provide cleaner way of doing this in the future
      def self.inject_subspec_dependencies
       @@lockfile.to_hash["PODS"].select { |dep|
         dep.is_a?(Hash)
       }.map { |dep|
         dep.values.first.map { |pod|
           pod = pod.split(" ").first
           parent = dep.keys.first.split(" ").first
           version = @@lockfile.version(parent)
           depen = Dependency.new(pod, version) #Get pod version
           transform_dependency_to_sandbox_podspec(depen)
         }
       }.flatten
      end
    end

    class Deploy < Command

      include Project

      self.summary = 'Install project dependencies to Podfile.lock versions without pulling down full podspec repo.'

      self.description = <<-DESC
        Install project dependencies to Podfile.lock versions without pulling down full podspec repo.
      DESC

      #TODO: Remove Hack to transform podfile dependencies to podspec ones - we should find
      #a way of removing some of these
      def apply_dependency_patches

        DeployTransformer.lockfile = config.lockfile

        Specification.class_eval do

          alias_method :original_all_dependencies, :all_dependencies

          def all_dependencies(platform = nil)
            new_deps = original_all_dependencies.map do |dep|

              unless dep.external_source
                DeployTransformer.transform_dependency_to_sandbox_podspec(dep)
              else
                dep
              end
            end + DeployTransformer.inject_subspec_dependencies

            new_deps.select do |dep|
              DeployTransformer.in_lockfile(dep)
            end
          end
        end

        Resolver.class_eval do

          alias_method :original_locked_dependencies, :locked_dependencies

          def dependencies
            new_deps = original_locked_dependencies.map do |dep|
              unless dep.external_source
                DeployTransformer.transform_dependency_to_sandbox_podspec(dep)
              else
                dep
              end
            end + DeployTransformer.inject_subspec_dependencies

            new_deps.select do |dep|
              DeployTransformer.in_lockfile(dep)
            end
          end
        end

        Podfile::TargetDefinition.class_eval do

          alias_method :original_dependencies, :dependencies

          def dependencies
            new_deps = original_dependencies.map do |dep|
              unless dep.external_source
                DeployTransformer.transform_dependency_to_sandbox_podspec(dep)
              else
                dep
              end
            end + DeployTransformer.inject_subspec_dependencies

            new_deps.select do |dep|
              DeployTransformer.in_lockfile(dep)
            end
          end
        end
      end

      def transform_dependency_and_version_to_remote_podspec(dep, version)
        unless dep.external_source
          checkout = { :podspec => podspec_url(dep.root_name, version) }
          dep.external_source = checkout
          dep.specific_version = nil
          dep.requirement = Requirement.create(checkout)
        end

        dep
      end

      def dependency_for_pod_and_version(pod, version)
        dep = config.lockfile.dependencies.detect { |d| d.root_name == pod }

        unless dep
          dep = Dependency.new(pod, version)
        end

        dep
      end

      def download_dependency(dep)
        source = ExternalSources.from_dependency(dep, config.podfile.defined_in_file)
        source.fetch(config.sandbox)
      end

      def transform_pod_and_version(pod, version)
        dep = dependency_for_pod_and_version(pod, version)
        transform_dependency_and_version_to_remote_podspec(dep, version)
        download_dependency(dep)
      end

      # This method sets up the enviroment to be optimised
      # for CocoaPod Deployment.
      #
      # Turning off things like repo cloning, clean-up and statistics.
      def setup_enviroment
        # Disable Cocoapods Stats - Due to
        # https://github.com/CocoaPods/cocoapods-stats/issues/28
        ENV['COCOAPODS_DISABLE_STATS'] = "1"

        # Disable updating of the CocoaPods Repo since we are directly
        # deploying using Podspecs
        config.skip_repo_update = true

        # Disable cleaning of the source file since we are deploying
        # and we don't need to keep things clean.
        config.clean = false
      end

      def run

        setup_enviroment
        return

        verify_podfile_exists!
        verify_lockfile_exists!

        UI.puts("- Deploying Pods")

        config.lockfile.pod_names.each do |pod|
          version = config.lockfile.version(pod)
          UI.puts("- Deploying #{pod} #{version}")
          transform_pod_and_version(pod, version)
        end

        run_install_with_update(false)
      end

      def run_install_with_update(update)

        #TODO: Somehow use a custom dependencies_to_lock_pod_named in the lockfile
        #TODO: Work out way of transforming dependencies without patch
        apply_dependency_patches

        installer = DeployInstaller.new(config.sandbox, config.podfile, config.lockfile)
        installer.update = update
        installer.install!
      end
    end
  end
end
