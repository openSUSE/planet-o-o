# frozen_string_literal: true

task default: %w[build]

task :build do
  system 'pluto update planet.ini'
  ruby 'bin/jekyll_planet.rb'
end

task :test do
  ruby 'tests/feedcheck.rb'
end
