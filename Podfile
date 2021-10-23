inhibit_all_warnings!
use_frameworks!

target "Groupir" do
    platform :ios, "14.0"
    pod 'BrightFutures'
    pod 'SnapKit'
    pod 'SVProgressHUD'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings.delete 'ARCHS'
            config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
        end
    end
end
