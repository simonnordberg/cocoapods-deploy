require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Deploy do

    before do
      @command = Command.parse(%w{ deploy })
      @command.stubs(:verify_lockfile_exists!)
      @command.stubs(:verify_podfile_exists!)

      @installer = DeployInstaller.new(@sandbox, @podfile, nil)
      @installer.stubs(:install!)

      DeployInstaller.stubs(:new).returns(@installer)
    end

    describe 'CLAide' do
      it 'registers it self' do
        @command.should.be.instance_of Command::Deploy
      end
    end

    describe 'setting up enviroment' do

      before do
        @command.stubs(:transform_podfile)
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

        @transformer = DeployTransformer.new(nil)

        @podfile = Podfile.new
        Config.instance.stubs(:podfile).returns(@podfile)

        @lockfile = Lockfile.new({})
        Config.instance.stubs(:lockfile).returns(@lockfile)
      end

      it 'should create transformer with lockfile' do
        DeployTransformer.expects(:new).with(@lockfile).returns(@transformer)
        @command.run
      end

      it 'should create transform podfile' do
        @transformer.expects(:transform_podfile).with(@podfile)

        DeployTransformer.stubs(:new).returns(@transformer)
        @command.run
      end
    end

    describe 'when installing' do |variable|

      before do
        @podfile = Podfile.new
        @command.stubs(:transform_podfile).returns(@podfile)
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
  end
end
