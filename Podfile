workspace 'WatchSync.xcworkspace'

target 'WatchSync iOS' do
  project 'WatchSync.xcodeproj'
  use_frameworks!

  pod 'GzipSwift'

  target 'WatchSync iOSTests' do
    inherit! :search_paths
    # Pods for testing
  end
end

target 'WatchSync watchOS' do
  project 'WatchSync.xcodeproj'
  use_frameworks!

  pod 'GzipSwift'
end

target 'WatchSync Example' do
  project 'WatchSync Example/WatchSync Example.xcodeproj'
  use_frameworks!

  pod 'WatchSync', :path => '.'
  pod 'SwiftLint', '0.31.0'
end

target 'WatchSync Example WatchKit Extension' do
  project 'WatchSync Example/WatchSync Example.xcodeproj'
  use_frameworks!

  pod 'WatchSync', :path => '.'
end
