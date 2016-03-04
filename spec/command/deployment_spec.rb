require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Deployment do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ deployment }).should.be.instance_of Command::Deployment
      end
    end
  end
end

