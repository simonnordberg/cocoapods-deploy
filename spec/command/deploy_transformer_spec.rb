require File.expand_path('../../spec_helper', __FILE__)

def transform_podfile(lockfile, sandbox, podfile)
  transformer = Pod::DeployTransformer.new(lockfile, sandbox)
  transformer.transform_podfile(podfile)
end

module Pod
  describe DeployTransformer do
    describe "when transforming podfile" do
      it "should preserve external dependencies" do
        lockfile = Lockfile.new({
          "CHECKOUT OPTIONS" => {"Polly" => {:git => "http://example.org"} }
        })
        original_podfile = Podfile.new do |p|
          p.pod "Polly", :git => "http://example.org"
        end

        podfile = transform_podfile(lockfile, nil, original_podfile)
        dependency = Dependency.new("Polly", {:git => "http://example.org"})
        podfile.dependencies.should.include dependency
      end

      describe "when transforming repo dependencies" do
        it "should abort when absent from lockfile" do
          lockfile = Lockfile.new({})
          original_podfile = Podfile.new do |p|
            p.pod "Mixpanel"
          end

          should.raise(Informative) {
            transform_podfile(lockfile, nil, original_podfile)
          }
        end

        it "should transform to Podspec URL" do
          lockfile = Lockfile.new({
            "PODS" => ["Mixpanel (1.0)"]
          })
          original_podfile = Podfile.new do |p|
            p.pod "Mixpanel"
          end

          podfile = transform_podfile(lockfile, nil, original_podfile)
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

            podfile = transform_podfile(lockfile, nil, original_podfile)
            dependency = Dependency.new("Google/Analytics", {:podspec => "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/Google/1.0/Google.podspec.json"})
            podfile.dependencies.should.include dependency
          end
        end
      end
    end

    describe "when transforming podspec dependencies" do

        before do
          @sandbox = Sandbox.new(".")
        end

        it "should abort when absent from lockfile" do
          spec = Specification.new do |s|
            s.dependency "Google"
          end
          @sandbox.stubs(:specification).returns(spec)

          lockfile = Lockfile.new({})
          original_podfile = Podfile.new do |p|
            p.pod "GoogleAnalytics"
          end

          should.raise(Informative) {
            transform_podfile(lockfile, @sandbox, original_podfile)
          }
      end

      it "should transform to Podspec URL" do

        spec = Specification.new do |s|
          s.dependency "Google"
        end
        @sandbox.stubs(:specification).returns(spec)

        lockfile = Lockfile.new({
          "PODS" => ["GoogleAnalytics (1.0)", "Google (1.0)"]
        })
        original_podfile = Podfile.new do |p|
          p.pod "GoogleAnalytics"
        end

        podfile = transform_podfile(lockfile, @sandbox, original_podfile)
        dependency = Dependency.new("Google", {:podspec => "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/Google/1.0/Google.podspec.json"})
        podfile.dependencies.should.include dependency
      end

      describe "which is a subspec" do
        it "should transform to Root Podspec URL" do
          spec = Specification.new do |s|
            s.dependency "Mixpanel/Mixpanel"
          end
          @sandbox.stubs(:specification).returns(spec)

          lockfile = Lockfile.new({
            "PODS" => ["ARAnalytics (1.0)", "Mixpanel/Mixpanel (1.0)"]
          })
          original_podfile = Podfile.new do |p|
            p.pod "ARAnalytics"
          end

          podfile = transform_podfile(lockfile, @sandbox, original_podfile)
          dependency = Dependency.new("Mixpanel/Mixpanel", {:podspec => "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/Mixpanel/1.0/Mixpanel.podspec.json"})
          podfile.dependencies.should.include dependency
        end
      end

      # TODO: Reducing duplicates

      # Figure out how to test external source here.

      # TODO: Test collect_podspec_dependencies as well
    end
  end
end
