module Pod
  class DeployInstaller < Installer
    def create_analyzer
      DeployAnalyzer.new(sandbox, podfile, lockfile).tap do |analyzer|
        analyzer.allow_pre_downloads = false
      end
    end

    def write_lockfiles
    end
  end
end
