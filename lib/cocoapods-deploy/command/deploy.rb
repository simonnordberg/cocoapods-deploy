module Pod
  class Command
    class Deploy < Command

      include Project

      self.summary = 'Install project dependencies to Podfile.lock versions without pulling down full podspec repo.'

      self.description = <<-DESC
        Install project dependencies to Podfile.lock versions without pulling down full podspec repo.
      DESC

      # This method sets up the environment to be optimised
      # for CocoaPod Deployment.
      #
      # Turning off things like repo cloning, clean-up and statistics.
      def setup_environment
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

      # Verify the environment is ready for deployment
      # i.e Do we have a podfile and lockfile.
      def verify_environment
        verify_podfile_exists!
        verify_lockfile_exists!
      end

      # This prepares the Podfile and Lockfile for deployment
      # by transforming Repo depedencies to Poddpec based dependencies
      # and making sure we have eveything we need for Subspecs which
      # typially don't work with Podspec based depedencies.
      def transform_podfile
        transformer = DeployTransformer.new(config.lockfile, config.sandbox)
        transformer.transform_podfile(config.podfile)
      end

      # Applies patch to external source so that it loops through all
      # the sources when fetching to avoid 404s for pods not from
      # the master repo.
      #
      def apply_external_source_patch
        ExternalSources::PodspecSource.class_eval do
          def fetch(sandbox)
            title = "Fetching podspec for `#{name}` #{description}"
            UI.titled_section(title,  :verbose_prefix => '-> ') do
              podspec_path = Pathname(podspec_uri)
              is_json = podspec_path.extname == '.json'
              if podspec_path.exist?
                store_podspec(sandbox, podspec_path, is_json)
              else
                require 'cocoapods/open-uri'
                begin
                  open(podspec_uri) { |io| store_podspec(sandbox, io.read, is_json) }
                rescue OpenURI::HTTPError => e
                  status = e.io.status.join(' ')
                  raise Informative, "Failed to fetch podspec for `#{name}` at `#{podspec_uri}`.\n Error: #{status}"
                end
              end
            end
          end
        end
      end

      # Applies patch to resolver as it needs help being pointed to use the
      # local podspecs due to limitations in CocoaPods. We may be able to remove
      # this in the future.
      #
      # In the future passing the lockfile into the resolve is hacked
      # potentially we could have a special deploy subclass.
      #
      # TODO: BDD
      def apply_resolver_patch
        Resolver.class_eval do

          def find_cached_set(dependency)
            name = dependency.root_name

            unless cached_sets[name]
              spec = sandbox.specification(name)
              set = Specification::Set::External.new(spec)
              cached_sets[name] = set
              unless set
                raise Molinillo::NoSuchDependencyError.new(dependency) # rubocop:disable Style/RaiseArgs
              end
            end

            cached_sets[name]
          end

          def dependencies_for(specification)
            dependencies = specification.all_dependencies.select { |dep|
              Config.instance.lockfile.version(dep.root_name) != nil
            }

            dependencies.map do |dependency|
              if dependency.root_name == Specification.root_name(specification.name)
                dependency.dup.tap { |d| d.specific_version = specification.version }
              else
                dependency
              end
            end
          end
        end
      end

      # Installs required sources for lockfile - TODO: Simplify code
      def install_sources_for_lockfile
        config.lockfile.pod_names.each do |pod|
          install_sources_for_pod(pod)
        end
      end

      # Installs required sources for pod.
      def install_sources_for_pod(pod)
        transformer = DeployTransformer.new(config.lockfile, config.sandbox)
        dep = transformer.transform_dependency_name(pod)

        source = ExternalSources.from_dependency(dep, config.podfile.defined_in_file)
        source.fetch(config.sandbox)
      end

      # Triggers the CocoaPods install process
      def install(podfile)
        installer = DeployInstaller.new(config.sandbox, podfile, nil)
        installer.install!
      end

      def run
        setup_environment
        verify_environment

        # TODO: BDD Patch
        apply_external_source_patch
        apply_resolver_patch

        install_sources_for_lockfile
        install(transform_podfile)
      end
    end
  end
end
