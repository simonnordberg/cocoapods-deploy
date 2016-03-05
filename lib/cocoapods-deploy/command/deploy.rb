module Pod
  class Command
    class Deploy < Command

      include Project

      self.summary = 'Install project dependencies to Podfile.lock versions without pulling down full podspec repo.'

      self.description = <<-DESC
        Install project dependencies to Podfile.lock versions without pulling down full podspec repo.
      DESC

      def initialize(argv)
        super
        apply_installer_patch
      end

      def validate!
        super
      end

      #Hack to be able to override source installer
      def apply_installer_patch
        Installer.class_eval do
          def create_analyzer
            Installer::Analyzer.new(sandbox, podfile, lockfile).tap do |analyzer|
              analyzer.allow_pre_downloads = false
              #analyzer.installation_options = installation_options
            end
          end
        end
      end

      def download
      end

      def podspec_url(pod, version)
        "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/#{pod}/#{version}/#{pod}.podspec.json"
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
        #Handle things we already have
        source = ExternalSources.from_dependency(dep, config.podfile.defined_in_file)
        source.fetch(config.sandbox)
      end

      def transform_pod_and_version(pod, version)
        dep = dependency_for_pod_and_version(pod, version)
        transform_dependency_and_version_to_remote_podspec(dep, version)
        download_dependency(dep)
      end

      def transform_dependency_and_version_to_sandbox_podspec(dep, version)
        unless dep.external_source
          checkout = { :podspec => podspec_url(dep.root_name, version) }
          dep.external_source = checkout
          dep.specific_version = nil
          dep.requirement = Requirement.create(checkout)
        end

        dep
      end

      def transform_target_dependencies(target)
        target.dependencies.each do |dep|
          version = config.lockfile.version(dep.name)
          transform_dependency_and_version_to_sandbox_podspec(dep, version)
        end
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

        config.podfile.target_definition_list.map do |target|
          transform_target_dependencies(target)
        end

        # Disable any kind of fetching and run the installer in a way that it
        # doesn't modify the lockfile and is able to use the sandbox to get the
        # just fetched specs
        run_install_with_update(false)
      end

      def run_install_with_update(update)

        #Force this to be true so it is always skipped
        config.skip_repo_update = true

        #Patch installer to provide our own analyzer we need to turn of fetching
        #until we can figure out how to do it manually
        apply_installer_patch

        installer = Installer.new(config.sandbox, config.podfile, nil)
        installer.update = update
        installer.install!
      end
    end
  end
end
