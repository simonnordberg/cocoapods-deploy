require File.expand_path('../../spec_helper', __FILE__)

class MockExternalSource
  def initialize
  end

  def fetch
  end
end

module Pod
  describe Command::Deploy do

    before do
      @command = Command.parse(%w{ deploy })
      @command.stubs(:verify_lockfile_exists!)
      @command.stubs(:verify_podfile_exists!)

      @podfile = Podfile.new
      Config.instance.stubs(:podfile).returns(@podfile)

      @lockfile = Lockfile.new({
        "PODS" => [
          "Google/Analytics (1.0)",
          "Mixpanel (1.0)"
        ]
      })
      Config.instance.stubs(:lockfile).returns(@lockfile)
    end

    describe 'CLAide' do
      it 'registers it self' do
        @command.should.be.instance_of Command::Deploy
      end
    end

    describe 'setting up enviroment' do

      before do
        @command.stubs(:transform_podfile)
        @command.stubs(:install_sources_for_lockfile)
        @command.stubs(:install)
      end

      it 'should disable cocoapods-stats' do
        ENV.expects(:[]=).with("COCOAPODS_DISABLE_STATS", "1")
        @command.run
      end

      it 'should skip repo update' do
        Config.instance.expects(:skip_repo_update=).with(true)
        @command.run
      end

      it 'should skip source file clean' do
        Config.instance.expects(:clean=).with(false)
        @command.run
      end

      it 'should verify podfile' do
        @command.expects(:verify_lockfile_exists!)
        @command.run
      end

      it 'should verify lockfile' do
        @command.expects(:verify_podfile_exists!)
        @command.run
      end
    end

    describe 'converting podfile dependencies' do

      before do
        @command.stubs(:install_sources_for_lockfile)
        @command.stubs(:install)

        @transformer = DeployTransformer.new(nil, nil)
      end

      it 'should create transformer with lockfile' do
        DeployTransformer.expects(:new).with(@lockfile, Config.instance.sandbox).returns(@transformer)
        @command.run
      end

      it 'should create transform podfile' do
        @transformer.expects(:transform_podfile).with(@podfile)

        DeployTransformer.stubs(:new).returns(@transformer)
        @command.run
      end
    end

    describe 'when installing' do

      before do
        @command.stubs(:install_sources_for_lockfile)
        @command.stubs(:transform_podfile).returns(@podfile)

        @installer = DeployInstaller.new(@sandbox, @podfile, nil)
        @installer.stubs(:install!)
        DeployInstaller.stubs(:new).returns(@installer)
      end

      it 'should create new installer' do
        DeployInstaller.expects(:new).with(Config.instance.sandbox, @podfile, nil).returns(@installer)
        @command.run
      end

      it 'should invoke installer' do
        @installer.expects(:install!)
        @command.run
      end
    end

    describe 'when downloading pod sources' do

      before do
        @dependency = Dependency.new("Google/Analytics")
        @lockfile.stubs(:pod_names).returns(["Google/Analytics"])

        @transformer = DeployTransformer.new(nil, nil)
        @transformer.stubs(:transform_dependency_name).with("Google/Analytics").returns(@dependency)
        DeployTransformer.stubs(:new).returns(@transformer)

        @source = MockExternalSource.new
        @command.stubs(:transform_podfile).returns(@podfile)
        @command.stubs(:install)
      end

      it 'should create new external source' do
        ExternalSources.expects(:from_dependency).with(@dependency, @podfile.defined_in_file).returns(@source)
        @source.stubs(:fetch)
        @command.run
      end

      it 'should fetch source' do
        ExternalSources.stubs(:from_dependency).returns(@source)
        @source.expects(:fetch)
        @command.run
      end

      describe 'when pod is from non master repo source' do

        it 'should fetch source from other repo' do

          # - Pod should be defined in Pod and Lockfile
          # - Pod should define another repo source
          # - Download method should try each source until it gets a hit
          # - If there isn't a hit then it should forward the method.

          # ExternalSources.stubs(:from_dependency).returns(@source)
          # @source.expects(:fetch)
          # @command.run
        end
      end
    end
  end
end
