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
      @podfile = Podfile.new
      Config.instance.stubs(:podfile).returns(@podfile)

      @source = MockExternalSource.new
      ExternalSources.stubs(:from_dependency).returns(@source)
    end

    it "should external source outside of repo" do
      dependency = Dependency.new("AFNetworking", { :git => "https://github.com/gowalla/AFNetworking.git"})
      downloader = DeployDownloader.new(dependency)

      @source.expects(:fetch)
      downloader.download(Config.instance)
    end

    it "should download source from main repo" do
      dependency = Dependency.new("AFNetworking", { :podspec => "http://github.com/CocoaPods/Specs.git/master/Specs/AFNetworking/1.0/AFNetworking.podspec.json"})
      downloader = DeployDownloader.new(dependency)

      @source.expects(:fetch)
      downloader.download(Config.instance)
    end

    it "should download source from external repo" do
      dependency = Dependency.new("AFNetworking", { :podspec => "http://github.com/My/Repo.git/master/Specs/AFNetworking/1.0/AFNetworking.podspec.json"})
      downloader = DeployDownloader.new(dependency)

      @source.expects(:fetch)
      downloader.download(Config.instance)
    end
  end
end
