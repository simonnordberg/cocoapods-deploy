require File.expand_path('../spec_helper', __FILE__)

class MockExternalSource
  def initialize
  end

  def fetch
  end
end

module Pod
  describe DeployDownloader do

    before do
      @downloader = DeployDownloader.new(nil)
      @source = MockExternalSource.new
    end

    it "should download source from main repo" do
      ExternalSources.stubs(:from_dependency).returns(@source)
      @source.expects(:fetch)
      @downloader.download(nil)
    end

    it "should download source from external repo" do
    end
  end
end
