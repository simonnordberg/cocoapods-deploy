require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe DeployTransformer do

    before do
      lockfile = Lockfile.new({})
      original_podfile = Podfile.new do |p|
        p.pod "Quick"

        p.target "yo" do
          pod "ARAnalytics", :subspecs => ["Mixpanel"]
          pod "Mixpanel", "1.2.0"
          pod "Polly", :git => "http://example.org"
          pod "Google/Analytics", "3.0"
        end
      end

      transformer = DeployTransformer.new(lockfile)
      @podfile = transformer.transform_podfile(original_podfile)
    end

    it "should preserve external dependencies" do
      dependency = Dependency.new("Polly", {:git => "http://example.org"})
      @podfile.dependencies.should.include dependency
    end
  end
end
