module Pod
  class DeploymentInstaller
    class DeploymentAnalyzer < Analyzer

      def analyze(allow_fetches = true)
        validate_podfile!
        validate_lockfile_version!
        @result = AnalysisResult.new
        if installation_options.integrate_targets?
          @result.target_inspections = inspect_targets_to_integrate
        else
          verify_platforms_specified!
        end
        @result.podfile_state = generate_podfile_state
        @locked_dependencies  = generate_version_locking_dependencies

        store_existing_checkout_options
        fetch_main_repo_specs if allow_fetches
        fetch_external_sources if allow_fetches
        @result.specs_by_target = validate_platforms(resolve_dependencies)
        @result.specifications  = generate_specifications
        @result.targets         = generate_targets
        @result.sandbox_state   = generate_sandbox_state
        @result
      end

      def dependencies_to_pull_from_main_repo
        @deps_to_fetch ||= begin
          deps_to_fetch = podfile.dependencies.select(&:external_source)
          deps_to_fetch.uniq(&:root_name)
        end
      end

      #Modify this to pull down the spec for a Main Repo spec
      def fetch_main_repo_specs
         return unless allow_pre_downloads?

         verify_no_pods_with_different_sources!
         unless dependencies_to_pull_from_main_repo.empty?
           UI.section 'Fetching external sources' do
             dependencies_to_fetch.sort.each do |dependency|
               fetch_external_source(dependency, !pods_to_fetch.include?(dependency.root_name))
             end
           end
         end
       end
    end
  end
end
