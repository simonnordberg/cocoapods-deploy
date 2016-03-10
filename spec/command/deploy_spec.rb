require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Deploy do

    before do
      @command = Command.parse(%w{ deploy })
    end

    describe 'CLAide' do
      it 'registers it self' do
        @command.should.be.instance_of Command::Deploy
      end
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
  end
end
