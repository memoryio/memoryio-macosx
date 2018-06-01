platform :osx, '10.8'
workspace 'memoryio-macosx'
project 'memoryio/memoryio.xcodeproj'

target "memoryio" do
pod 'SimpleExif', :git => 'git@github.com:jacobrosenthal/SimpleExif.git', :branch => 'memoryio'
pod 'NSGIF', :git => 'git@github.com:jacobrosenthal/NSGIF.git', :branch => 'memoryio'
pod 'AVCapture', :git => 'git@github.com:jacobrosenthal/AVCapture.git'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.8'
    end
  end
end
