Pod::Spec.new do |s|
  s.name             = "GDIImageOperation"
  s.version          = "0.1.3"
  s.summary          = "GDIImageOperation is an NSOperation subclass for modern, fast image loading."
  s.description      = <<-DESC
                       GDIImageOperation is an NSOperation subclass that makes use of NSURLSession for requests, NSCache
                       for in memory caching, and also caches images to disk.
                       
                       This project is similar to SDWebImage but is lighter weight and the GDIImageOperation can be 
                       used independently for custom download tasks. GDIImageOperation also uses iOS7+ APIs and supports
                       using custom NSURLSession and custom configuration for caching rules.
                       
                       This project also includes a category on UIImageView to asynchronous loading images from cache,
                       or network, when necessary. 
                       DESC
  s.homepage         = "https://github.com/gdavis/GDIImageOperation"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Grant Davis" => "grant.davis@gmail.com" }
  s.source           = { :git => "https://github.com/gdavis/GDIImageOperation.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/gravitybytes'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'GDIImageOperation/*'
  s.frameworks = 'UIKit'
end
