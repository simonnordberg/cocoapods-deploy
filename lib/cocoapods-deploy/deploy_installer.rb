module Pod
  class DeployInstaller < Installer
    def create_analyzer
      DeployAnalyzer.new(sandbox, podfile, lockfile).tap do |analyzer|
        analyzer.installation_options = installation_options
      end
    end
  end
end
