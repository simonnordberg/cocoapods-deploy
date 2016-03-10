require File.expand_path('../../spec_helper', __FILE__)

def transform(lockfile, podfile)
  transformer = Pod::DeployTransformer.new(lockfile)
  transformer.transform_podfile(podfile)
end

module Pod
  describe DeployTransformer do

    it "should preserve external dependencies" do
      lockfile = Lockfile.new({})
      original_podfile = Podfile.new do |p|
        p.pod "Polly", :git => "http://example.org"
      end

      podfile = transform(lockfile, original_podfile)
      dependency = Dependency.new("Polly", {:git => "http://example.org"})
      podfile.dependencies.should.include dependency
    end

    describe "when transforming repo dependencies" do
      it "should abort when one isn't in the lockfile" do
        lockfile = Lockfile.new({})
        original_podfile = Podfile.new do |p|
          p.pod "Mixpanel"
        end

        should.raise(RuntimeError) {
          transform(lockfile, original_podfile)
        }
      end
    end
  end
end
