require File.expand_path('../../spec_helper', __FILE__)

def transform_podfile(lockfile, podfile)
  transformer = Pod::DeployTransformer.new(lockfile)
  transformer.transform_podfile(podfile)
end

def transform_specification(lockfile, spec)
  transformer = Pod::DeployTransformer.new(lockfile)
  transformer.transform_specification(spec)
end

module Pod
  describe DeployTransformer do
    describe "when transforming podfile" do
      it "should preserve external dependencies" do
        lockfile = Lockfile.new({})
        original_podfile = Podfile.new do |p|
          p.pod "Polly", :git => "http://example.org"
        end

        podfile = transform_podfile(lockfile, original_podfile)
        dependency = Dependency.new("Polly", {:git => "http://example.org"})
        podfile.dependencies.should.include dependency
      end

      describe "when transforming repo dependencies" do
        it "should abort when absent from lockfile" do
          lockfile = Lockfile.new({})
          original_podfile = Podfile.new do |p|
            p.pod "Mixpanel"
          end

          should.raise(RuntimeError) {
            transform_podfile(lockfile, original_podfile)
          }
        end

        it "should transform to Podspec URL" do
          lockfile = Lockfile.new({
            "PODS" => ["Mixpanel (1.0)"]
          })
          original_podfile = Podfile.new do |p|
            p.pod "Mixpanel"
          end

          podfile = transform_podfile(lockfile, original_podfile)
          dependency = Dependency.new("Mixpanel", {:podspec => "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/Mixpanel/1.0/Mixpanel.podspec.json"})
          podfile.dependencies.should.include dependency
        end

        describe "which is a subspec" do
          it "should transform to Root Podspec URL" do
            lockfile = Lockfile.new({
              "PODS" => ["Google/Analytics (1.0)"]
            })
            original_podfile = Podfile.new do |p|
              p.pod "Google/Analytics"
            end

            podfile = transform_podfile(lockfile, original_podfile)
            dependency = Dependency.new("Google/Analytics", {:podspec => "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/Google/1.0/Google.podspec.json"})
            podfile.dependencies.should.include dependency
          end
        end
      end
    end

    describe "when transforming specification" do
    end
  end
end
