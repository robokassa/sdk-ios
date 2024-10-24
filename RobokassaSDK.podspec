Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name           = 'RobokassaSDK'
  spec.version        = '1.0.0'
  spec.summary        = 'Robokassa iOS SDK'
  spec.description    = 'Robokassa SDK позволяет интегрировать прием платежей через сервис Robokassa в мобильное приложение iOS'
  spec.homepage       = 'https://robokassa.com'
  spec.license        = 'MIT'
  spec.author         = { 'Robokassa' => ' support@robokassa.ru' }
  spec.platform       = :ios, '14.0'
  spec.source         = { :git => 'https://github.com/madjios/RobokassaSDK.git', :tag => spec.version }
  spec.ios.deployment_target = '14.0'
  spec.source_files   = 'Robokassa/**/*.{swift}'
  spec.swift_versions = '5.0'
  
  # spec.exclude_files = "Classes/Exclude"
  # spec.public_header_files = "Classes/**/*.h"
  # spec.framework  = "SomeFramework"
  # spec.frameworks = "SomeFramework", "AnotherFramework"
  # spec.library   = "iconv"
  # spec.libraries = "iconv", "xml2"
  # spec.requires_arc = true
  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # spec.dependency "JSONKit", "~> 1.4"

end
