require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe DeployTransformer do

    it "should do magic" do
      lockfile = Lockfile.new({})
      podfile = Podfile.new do |p|
        p.pod "Quick"

        p.target "yo" do
          pod "ARAnalytics", :subspecs => ["Mixpanel"]
          pod "Mixpanel", "1.2.0"
          pod "Polly", :git => "http://example.org"
          pod "Google/Analytics", "3.0"
        end
      end

      t = DeployTransformer.new(lockfile)
      t.transform_podfile(podfile)
      t.should.not.equal nil
    end
  end
end
