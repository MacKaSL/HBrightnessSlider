Pod::Spec.new do |s|

  # ―――----------------------------------――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name         = "HBrightnessSlider"
  s.version      = "1.0.0"
  s.summary      = "A slider control like in Control Center"
  s.description  = "A fully configurable slider control just like in iOS Control Center."
  s.documentation_url = 'https://github.com/MacKaSL/HBrightnessSlider/blob/master/README.md'
  s.homepage     = "https://himalmadhushan.weebly.com/"
  s.license            = { :type => 'MIT', :file => 'LICENSE' }
  s.author             = { "Himal Madhushan" => "mackacodes@gmail.com" }
  s.social_media_url   = "https://twitter.com/himalmadhushan"

  # ―――----------------------------------――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.platform     = :ios, "9.0"

  s.ios.vendored_frameworks = 'HBrightnessSlider.framework'

  s.source       = { :http => 'https://github.com/MacKaSL/HBrightnessSlider/blob/master/HBrightnessSlider.zip?raw=true' }

  s.swift_version = '4.0'
end