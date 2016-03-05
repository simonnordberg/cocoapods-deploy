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
            podfile.dependencies
          end

          def pods_to_fetch
            podfile.dependencies
          end

          #Hack to download dependencies when not found
          def apply_resolver_patch
            Resolver.class_eval do

              def lockfile=(lockfile)
                @lockfile = lockfile
              end

              def find_cached_set(dependency)

                name = dependency.root_name
                    unless cached_sets[name]
                      spec = sandbox.specification(name)

                      unless spec
                      puts "Boom"
                      source = ExternalSources.from_dependency(dependency, podfile.defined_in_file)
                      spec = source.fetch(sandbox)
                      end

                      unless spec
                        raise StandardError, '[Bug] Unable to find the specification ' \
                          "for `#{dependency}`."
                      end
                      set = Specification::Set::External.new(spec)

                      cached_sets[name] = set
                      unless set
                        raise Molinillo::NoSuchDependencyError.new(dependency) # rubocop:disable Style/RaiseArgs
                      end
                    end
                    cached_sets[name]
                  end
                end
              end

              def search_for(dependency)

                unless dependency.external_source
                  version = @lockfile.version(dependency.name)
                  url = "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/#{dependency.root_name}/#{version}/#{dependency.root_name}.podspec.json"

                  dependency.external_source = { :podspec => url }
                  dependency.specific_version = nil
                  dependency.requirement = Requirement.create({ :podspec => url })
                end

                @search ||= {}
                @search[dependency] ||= begin
                  requirement = Requirement.new(dependency.requirement.as_list << requirement_for_locked_pod_named(dependency.name))
                  find_cached_set(dependency).
                    all_specifications.
                    select { |s| requirement.satisfied_by? s.version }.
                    map { |s| s.subspec_by_name(dependency.name, false) }.
                    compact.
                    reverse
                end
                @search[dependency].dup
              end
            end
          end

          def resolve_dependencies
            apply_resolver_patch

            duplicate_dependencies = podfile.dependencies.group_by(&:name).
              select { |_name, dependencies| dependencies.count > 1 }
            duplicate_dependencies.each do |name, dependencies|
              UI.warn "There are duplicate dependencies on `#{name}` in #{UI.path podfile.defined_in_file}:\n\n" \
               "- #{dependencies.map(&:to_s).join("\n- ")}"
            end

            specs_by_target = nil
            UI.section "Resolving dependencies of #{UI.path(podfile.defined_in_file) || 'Podfile'}" do
              resolver = Resolver.new(sandbox, podfile, locked_dependencies, sources)
              resolver.lockfile = @lockfile
              specs_by_target = resolver.resolve
              specs_by_target.values.flatten(1).each(&:validate_cocoapods_version)
            end
            specs_by_target
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
            original_dependencies.map do |dep|

              unless dep.external_source
                version = @lockfile.version(dep.name)
                url = "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/#{dep.root_name}/#{version}/#{dep.root_name}.podspec.json"

                dep.external_source = { :podspec => url }
                dep.specific_version = nil
                dep.requirement = Requirement.create({ :podspec => url })
              end

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
