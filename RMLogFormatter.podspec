Pod::Spec.new do |s|
  s.name             = "RMLogFormatter"
  s.version          = "0.1.2"
  s.summary          = "An informative, concise, and configurable CocoaLumberjack log formatter."
  s.description      = <<-DESC
                       RMLogFormatter is a configurable, word wrapping CocoaLumberjack log formatter.  The default log format is as follows:

                       * yyyy-MM-dd HH:mm:ss.SSS | FILENAME:LINE_NUMBER (TID:THREAD_ID) : LOG_MESSAGE
                       DESC
  s.homepage           = "https://github.com/rmaloney3/RMLogFormatter"
  s.license            = { :type => 'MIT', :file => 'LICENSE' }
  s.author             = { "Ryan Maloney" => "ryan_maloney@me.com" }
  s.source             = { :git => "https://github.com/rmaloney3/RMLogFormatter.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/rmaloney3'

  s.platform           = :ios, '7.0'
  s.requires_arc       = true

  s.source_files       = 'RMLogFormatter/*{m,h}'

  s.dependency 'CocoaLumberjack', '~> 2.0'
end
