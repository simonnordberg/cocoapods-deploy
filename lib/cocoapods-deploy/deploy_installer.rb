require 'cocoapods'

module Pod
  class DeployInstaller < Installer

    def create_analyzer
      DeployAnalyzer.new(sandbox, podfile, lockfile).tap do |analyzer|
        analyzer.installation_options = super.installation_options
      end
    end
  end
end
