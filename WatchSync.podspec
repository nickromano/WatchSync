Pod::Spec.new do |s|
  s.name         = "WatchSync"
  s.version      = "0.0.1"
  s.summary      = "WatchConnectivity wrapper with typed messages, better error handling, and simplified subscription APIs."

  s.description  = <<-DESC
    Use WatchSync as the WatchConnectivity delegate for your application.  It allows you to send typed messages (using `Codable`), 
    receive messages using closures anywhere in your application, and provides better error handling when connectivity isn't working.
                   DESC

  s.homepage     = "https://github.com/nickromano/WatchSync"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Nick Romano" => "nick.r.romano@gmail.com" }

  s.ios.deployment_target = '9.3'
  s.watchos.deployment_target = '3.0'

  s.source       = { :git => "https://github.com/nickromano/WatchSync.git", :tag => "#{s.version}" }

  s.source_files  = "Sources/**/*.{h,swift}"
  s.swift_version = "4.1"

  s.framework  = "WatchConnectivity"
end
