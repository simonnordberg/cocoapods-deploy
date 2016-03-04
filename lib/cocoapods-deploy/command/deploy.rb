module Pod
  class Command
    # This is an example of a cocoapods plugin adding a top-level subcommand
    # to the 'pod' command.
    #
    # You can also create subcommands of existing or new commands. Say you
    # wanted to add a subcommand to `list` to show newly deprecated pods,
    # (e.g. `pod list deprecated`), there are a few things that would need
    # to change.
    #
    # - move this file to `lib/pod/command/list/deprecated.rb` and update
    #   the class to exist in the the Pod::Command::List namespace
    # - change this class to extend from `List` instead of `Command`. This
    #   tells the plugin system that it is a subcommand of `list`.
    # - edit `lib/cocoapods_plugins.rb` to require this file
    #
    # @todo Create a PR to add your plugin to CocoaPods/cocoapods.org
    #       in the `plugins.json` file, once your plugin is released.
    #
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

      #Hack to force locked dependencies to be installed
      def apply_target_patch
        Podfile::TargetDefinition.class_eval do

          alias_method :original_dependencies, :dependencies

          def lockfile=(lockfile)
            @lockfile = lockfile
          end

          def dependencies
            original_dependencies.reject(&:external_source).map do |dep|

              version = @lockfile.version(dep.name)
              url = "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/#{dep.root_name}/#{version}/#{dep.root_name}.podspec.json"

              dep.external_source = { :podspec => url }
              dep.specific_version = nil
              dep.requirement = Requirement.create({ :podspec => url })

              dep
            end
          end
        end
      end

      #Hack to be able to override source installer
      def apply_installer_patch
        Installer::Analyzer.class_eval do
          def sources
            []
          end

          def generate_podfile_state
            nil
          end

          def store_existing_checkout_options
          end

          def verify_no_pods_with_different_sources!
          end

          def podfile_needs_install?(analysis_result)
            false
          end

          def dependencies_to_fetch
            self.podfile.dependencies
          end

          def pods_to_fetch
            self.podfile.dependencies
          end

          def generate_version_locking_dependencies
             Installer::Analyzer::LockingDependencyAnalyzer.generate_version_locking_dependencies(lockfile, [])
          end
        end
      end

      #Hack to be able to override dependencies
      def apply_podfile_patch
        Podfile.class_eval do

          alias_method :original_dependencies, :dependencies

          def lockfile=(lockfile)
            @lockfile = lockfile
          end

          def dependencies
            original_dependencies.reject(&:external_source).map do |dep|

              version = @lockfile.version(dep.name)
              url = "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/#{dep.root_name}/#{version}/#{dep.root_name}.podspec.json"

              dep.external_source = { :podspec => url }
              dep.specific_version = nil
              dep.requirement = Requirement.create({ :podspec => url })

              dep
            end
          end

          def target_definition_list
            root_target_definitions.map { |td| [td, td.recursive_children] }.flatten.map do |target|
              target.lockfile = @lockfile
              target
            end
          end
        end
      end

      def run
        verify_podfile_exists!
        verify_lockfile_exists!

        apply_target_patch
        apply_podfile_patch

        #Hack to be able to override dependencies
        config.podfile.lockfile = config.lockfile

        config.skip_repo_update = true
        run_install_with_update(false)
      end
    end
  end
end
