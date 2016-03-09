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
          dep.specific_version = nil
          dep.requirement = Requirement.create(checkout)
        end

        dep
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
            deps = original_all_dependencies(platform = nil).select do |dep|
              DeployTransformer.in_lockfile(dep)
            end

            deps.map do |dep|

              unless dep.external_source
                DeployTransformer.transform_dependency_to_sandbox_podspec(dep)
              else
                dep
              end
            end
          end
        end

        Resolver.class_eval do

          alias_method :original_locked_dependencies, :locked_dependencies

          def dependencies
            original_locked_dependencies.map do |dep|

              unless dep.external_source
                DeployTransformer.transform_dependency_to_sandbox_podspec(dep)
              else
                dep
              end
            end
          end
        end

        Podfile::TargetDefinition.class_eval do

          alias_method :original_dependencies, :dependencies

          def dependencies
            original_dependencies.map do |dep|

              unless dep.external_source
                DeployTransformer.transform_dependency_to_sandbox_podspec(dep)
              else
                dep
              end
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

      def run
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
        ENV['COCOAPODS_DISABLE_STATS'] = true #Disable Cocoapods Stats
        config.skip_repo_update = true #Force this to be true so it is always skipped
        config.clean = false #Disable source files from being cleaned
        
        #TODO: Work out way of transforming dependencies without patch
        apply_dependency_patches

        installer = DeployInstaller.new(config.sandbox, config.podfile, config.lockfile)
        installer.update = update
        installer.install!
      end
    end
  end
end
