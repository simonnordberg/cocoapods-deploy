require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Deploy do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ deploy }).should.be.instance_of Command::Deploy
      end
    end

    it 'should disable cocoapods-stats' do
      expect(ENV["COCOAPODS_DISABLE_STATS"]).to equal("1")
    end
  end
end
