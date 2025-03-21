#
# Be sure to run `pod lib lint OktaWithWink.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OktaWithWink'
  s.version          = '1.0.0'
  s.summary          = 'An iOS SDK for integrating Okta authentication into Swift applications with Okta OIDC support.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'An iOS SDK for integrating Okta authentication into Swift applications with Okta OIDC support and biometric support'

  s.homepage         = 'https://github.com/swatiappzlogic/CustomOkta.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Swati Sharma' => 'swati.sharma@appzlogic.com' }
  s.source           = { :git => 'https://github.com/swatiappzlogic/CustomOkta.git', :tag => '1.0.0' }

  s.ios.deployment_target = '16.0'
  s.swift_versions = '5.0'

  s.source_files = 'OktaWithWink/Classes/**/*'
  
  s.ios.resource_bundle = { 'WinkResources' => 'OktaWithWink/WinkResources/*' }
    s.dependency 'Alamofire', '~> 5.0'
    s.dependency 'NVActivityIndicatorView'
    s.dependency 'ADCountryPicker'
    s.dependency 'DatePicker', '~> 1.3.0'
    s.dependency "FlagPhoneNumber"
    s.dependency 'PhoneNumberKit', '~> 3.7'
  
  s.static_framework = true
  
end
