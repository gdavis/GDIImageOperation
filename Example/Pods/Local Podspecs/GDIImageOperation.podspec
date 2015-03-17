Pod::Spec.new do |s|
  s.name             = "GDIImageOperation"
  s.version          = "0.1.0"
  s.summary          = "GDIImageOperation is an NSOperation subclass that simplifies image loading."
  s.description      = <<-DESC
                       GDIImageOperation is an NSOperation subclass that simplifies image loading.
                       More information coming soonish.
                       DESC
  s.homepage         = "https://github.com/gdavis/GDIImageOperation"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Grant Davis" => "grant.davis@gmail.com" }
  s.source           = { :git => "https://github.com/gdavis/GDIImageOperation.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/ghunterdavis'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'GDIImageOperation' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
  # s.dependency 'Gravity', '~> 1.1.3'
end
