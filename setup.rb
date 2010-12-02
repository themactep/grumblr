#!/usr/bin/env ruby

require 'rubygems'
require 'ftools'

unless Process.uid == 0
  puts "Must run as root"
  exit
end

version = File.open('VERSION') { |f| f.read }

Gem.path.each do |path|
  puts "Checking out #{path}"
  path = File.join(path, 'gems', "grumblr-#{version}")
  unless File.directory?(path)
    puts " Gem not found\n\n"
    next
  end
  puts " Gem found!"
  puts " Copying data:"

  target = '/usr/share/pixmaps/grumblr.svg'
  if File.exists?(target)
    puts " - #{target} exists, skipping."
  else
    puts " + #{target} does not exist. copying"
    File.copy File.join(path, 'data', 'pixmaps', 'grumblr.svg'),
              target, :verbose => true
  end

  target = '/usr/share/applications/grumblr.desktop'
  if File.exists?(target)
    puts " - #{target} exists, skipping."
  else
    puts " + #{target} does not exist, copying"
    File.copy File.join(path, 'data', 'grumblr.desktop'),
              target, :verbose => true
  end

  target = '/usr/local/bin/grumblr'
  if File.exists?(target)
    puts " - #{target} exists, linking."
  else
    puts " + #{target} does not exist, copying"
    File.symlink File.join(path, 'bin', 'grumblr'), target
  end
end
