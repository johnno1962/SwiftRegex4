Pod::Spec.new do |s|
    s.name        = "SwiftRegex4"
    s.version     = "4.1"
    s.summary     = "Regular expressions for Swift 4"
    s.homepage    = "https://github.com/johnno1962/SwiftRegex4"
    s.social_media_url = "https://twitter.com/Injection4Xcode"
    s.documentation_url = "https://github.com/johnno1962/SwiftRegex4/blob/master/README.md"
    s.license     = { :type => "MIT" }
    s.authors     = { "johnno1962" => "swiftregex@johnholdsworth.com" }

    s.osx.deployment_target = "10.11"
    s.source   = { :git => "https://github.com/johnno1962/SwiftRegex4.git", :tag => s.version }
    s.source_files = "SwiftRegex4.playground/Sources/*.swift"
end
