#!/usr/bin/env ruby

require 'rubygems'
require 'id3lib'

if ARGV.length > 0
  ARGV.each do |a|
    puts "Processing argument: #{a}"

    if File.directory?(a)
      # change to directory from command line argument
      Dir.chdir(a)
      puts "Now processing files in dir #{Dir.pwd}"

      # get all mp3 files in directory (and subdirs)
      files = Dir.glob("**/*.mp3")

      if files.length > 0
        files.each do |f|
          puts " * Processing file: #{f}"

          # Load a tag from a file
          tag = ID3Lib::Tag.new(f)

          # get music information 
          title  = tag.title
          album  = tag.album
          artist = tag.artist

          puts " ** tags: artist: '#{artist}', album: '#{album}', title: '#{title}'"

=begin
          # Get info about APIC frame to see which fields are allowed
          ID3Lib::Info.frame(:APIC)
          #=> [ 2, :APIC, "Attached picture",
          #=>   [:textenc, :mimetype, :picturetype, :description, :data] ]

          # Add an attached picture frame
          cover = {
            :id          => :APIC,
            :mimetype    => 'image/jpeg',
            :picturetype => 3,
            :description => 'Cover',
            :textenc     => 0,
            :data        => File.read('cover.jpg')
          }
          tag << cover

          # Last but not least, apply changes
          tag.update!
=end
        end
      else
        puts " * No files in directory #{Dir.pwd} found for processing"
      end
    else
      puts "#{a} is not a directory"
    end
  end
else
  puts "missing arguments: please pass at least one directory path"
end
