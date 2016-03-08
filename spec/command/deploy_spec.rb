require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Deploy do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ deploy }).should.be.instance_of Command::Deploy
      end
    end
  end
end
