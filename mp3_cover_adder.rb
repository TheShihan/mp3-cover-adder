#!/usr/bin/env ruby

require 'id3lib'
require 'open-uri'
require 'rails'
require 'rubygems'
require 'scrobbler'
require 'time'

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

          unless tag.nil?
            # get music information 
            title  = tag.title
            album  = tag.album
            artist = tag.artist

            puts " ** tags: artist: '#{artist}', album: '#{album}', title: '#{title}'"

            # check if album cover art already present
            contains_cover = false
            tag.entries.each do |e|
              if e.has_key?(:id) and e[:id] == :APIC
                contains_cover = true
                break
              end
            end

            unless contains_cover
              # cover art missing in file
              puts " *** Cover art missing, trying to get one"

              # access Last.fm information
              unless album.nil? || artist.nil?
                album = Scrobbler::Album.new(artist, album, :include_info => true)

                cover_url  = album.image_large

                unless cover_url.nil?
                  img_tmp_filename = 'image.tmp'
                  File.open(img_tmp_filename, 'wb') do |file|
                    file.print open(cover_url).read
                  end

                  unless f.nil? 
                    # tmp image could be created
                    puts " **** Inserting new cover into file"
                    
                    content_type = 'image/jpg'

                    open(cover_url) do |tmp_cover_file|
                      content_type_src = tmp_cover_file.content_type

                      content_type = content_type_src unless content_type_src.nil?
                    end
                    
                    cover = {
                      :id          => :APIC,
                      :mimetype    => content_type, 
                      :picturetype => 3,
                      :description => 'Cover',
                      :textenc     => 0,
                      :data        => File.read(img_tmp_filename)
                    }
                    tag << cover

                    #save new cover
                    tag.update!

                    # new cover image saved
                    puts " ***** New cover image stored in file"
                    
                    # delete temporary file
                    File.delete(img_tmp_filename)
                  else
                    puts " **** New cover couldn't be downloaded"
                  end
                end
              end
            else
              # cover already present
              puts " *** Cover art already present"
            end
          else
            puts " *** Tag could not be determined"
          end
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
