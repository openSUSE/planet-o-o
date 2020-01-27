task default: %w[build]

task :build do
  system 'pluto update planet.ini'
  ruby 'bin/jekyll-planet.rb'
end

task :test do
  ruby 'tests/feedcheck.rb'
end
