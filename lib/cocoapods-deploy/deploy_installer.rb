require 'cocoapods'

module Pod
  class DeployInstaller < Installer

    def create_analyzer

      # Workaround for fact we can't get access to `installation_options`
      original_analyzer = super

      DeployAnalyzer.new(sandbox, podfile, lockfile).tap do |analyzer|
        analyzer.installation_options = original_analyzer.installation_options
      end
    end
  end
end
