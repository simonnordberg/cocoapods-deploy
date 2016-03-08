# cocoapods-deploy

CocoaPods Deploy is a plugin which tries to mimic the behaviour of bundlers `--deployment` mode.

The goal is to download and install the specific dependency versions from the `Podfile.lock` without having to pull down the full CocoaPods specs repo.


## Installation

    $ gem install cocoapods-deploy

## Usage

    $ pod deploy

This will look at the dependencies in your `Podfile.lock` and will install them up to 85% faster than `pod install`. If you don't have a `Podfile.lock` then you will still need to run `pod install` and `pod update` first.
