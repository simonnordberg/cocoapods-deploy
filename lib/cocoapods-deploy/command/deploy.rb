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
        transformer = DeployTransformer.new(config.lockfile)
        transformer.transform_podfile(config.podfile)
      end

      def run
        setup_environment
        verify_environment

        #TODO: BDD Below
        podfile = transform_podfile

        installer = DeployInstaller.new(config.sandbox, podfile, nil)
        installer.install!
      end
    end
  end
end
