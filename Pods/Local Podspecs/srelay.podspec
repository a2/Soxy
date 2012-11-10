Pod::Spec.new do |s|
  s.name         = "srelay"
  s.version      = "0.4.5b5"
  s.summary      = "A Free SOCKS server for UNIX"
  s.homepage     = "http://sourceforge.net/projects/socks-relay/"
  s.license      = 'BSD License'
  s.author       = { "Tomo M." => "http://twitter.com/bulkstream",
                     "Jérôme Lebel" => "https://github.com/jeromelebel",
                     "Alexsander Akers" => "a2@pandamonia.us" }
  s.source       = { :git => "https://github.com/a2/srelay.git", :branch => "iproxy" }
  s.source_files = '*.{h,c}'
  s.xcconfig     = { 'GCC_PREPROCESSOR_DEFINITIONS' => "HAVE_SOCKADDR_DL_STRUCT MACOSX HAVE_UINT32_T HAVE_SOCKLEN_T USE_THREAD=1" }
end
