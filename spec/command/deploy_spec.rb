require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Deploy do

    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ deploy }).should.be.instance_of Command::Deploy
      end
    end

    it 'should disable cocoapods-stats' do
      command = Command.parse(%w{deploy})
      ENV.expects(:[]=).with("COCOAPODS_DISABLE_STATS", "1")
      command.run
    end

    it 'should skip repo update' do
      command = Command.parse(%w{deploy})
      Config.instance.expects(:skip_repo_update=).with(true)
      command.run
    end

    it 'should skip source file clean' do
      command = Command.parse(%w{deploy})
      Config.instance.expects(:clean=).with(false)
      command.run
    end
  end
end
