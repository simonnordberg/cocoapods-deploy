require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe DeployAnalyzer do
    it "should have no sources" do
      analyzer = Analyzer.new()
      analyzer.sources.should.equal []
    end
  end
end
