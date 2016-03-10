require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Deploy do

    before do
      @command = Command.parse(%w{ deploy })
      @command.stubs(:verify_lockfile_exists!)
      @command.stubs(:verify_podfile_exists!)
    end

    describe 'CLAide' do
      it 'registers it self' do
        @command.should.be.instance_of Command::Deploy
      end
    end

    describe 'setting up enviroment' do

      before do
        @command.stubs(:prepare_for_deployment)
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
        @podfile = Podfile.new
        Config.instance.stubs(:podfile).returns(@podfile)

        @lockfile = Lockfile.new({})
        Config.instance.stubs(:lockfile).returns(@lockfile)
      end

      it 'should create transformer with lockfile' do
        @command.run
        @command.transformer.should.not.equal nil
        @command.transformer.lockfile.should.equal @lockfile
      end

      it 'should create transform podfile' do
        @command.transformer = DeployTransformer.new(@lockfile)
        @command.transformer.expects(:transform_podfile).with(@podfile)
        @command.run
      end

    end
  end
end
