Pod::Spec.new do |s|
  s.name         = "polipo"
  s.version      = "1.0.5"
  s.summary      = "The Polipo caching HTTP proxy."
  s.homepage     = "http://www.pps.jussieu.fr/~jch/software/polipo/"
  s.license      = { :type => 'MIT', :file => 'COPYING' }
  s.author       = { "Juliusz Chroboczek" => "http://www.pps.univ-paris-diderot.fr/~jch/",
                     "Jérôme Lebel" => "https://github.com/jeromelebel/",
                     "Alexsander Akers" => "a2@pandamonia.us" }
  s.source       = { :git => "https://github.com/a2/polipo.git", :branch => "iproxy" }
  s.source_files = '*.{h,c}'
  s.xcconfig     = { 'GCC_PREPROCESSOR_DEFINITIONS' => "NO_FANCY_RESOLVER" }
end
