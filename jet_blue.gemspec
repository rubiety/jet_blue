# Provide a simple gemspec so you can easily use your enginex
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.name = "jet_blue"
  s.summary = "Programatic access to the JetBlue booking engine (screen scraping)."
  s.description = "Uses mechanize and nokogiri to automate access to the JetBlue AYCJ booking engine (also used for BluePass)."
  s.files = Dir["{app,lib,config}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.rdoc"]
  s.version = "0.0.1"
end