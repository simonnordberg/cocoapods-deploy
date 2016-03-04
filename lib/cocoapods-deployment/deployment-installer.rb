module Pod
  class DeploymentInstaller < Installer
    def create_analyzer
      DeploymentAnalyzer.new(sandbox, podfile, lockfile).tap do |analyzer|
        analyzer.installation_options = installation_options
      end
    end
  end
end
