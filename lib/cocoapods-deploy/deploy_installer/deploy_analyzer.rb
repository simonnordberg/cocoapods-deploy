module Pod
  class Installer
    class DeployAnalyzer < Analyzer

      include Config::Mixin
      include InstallationOptions::Mixin

      def sources
          []
      end
    end
  end
end
