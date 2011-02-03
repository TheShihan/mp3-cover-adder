#!/usr/bin/env ruby

require 'id3lib'
require 'open-uri'
require 'rails'
require 'scrobbler'
require 'time'

if ARGV.length > 0
  start_time = Time.now

  ARGV.each do |a|
    puts "Processing argument: #{a}"

    if File.directory?(a)
      # change to directory from command line argument
      Dir.chdir(a)
      puts "Now processing files in dir #{Dir.pwd}"

      # get all mp3 files in directory (and subdirs)
      files = Dir.glob("**/*.{mp3,Mp3,mP3,MP3}")

      puts " * No files in directory #{Dir.pwd} found" if files.length < 1

      puts "   Found #{files.length} file(s) to process"
      processed_files = 0

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

          # check if album cover art missing
          if (tag.entries.select { |h| h[:id] == :APIC }).empty? == true
            puts " *** Cover art missing, trying to get one"

            # access Last.fm information
            unless album.nil? || artist.nil? || album.length < 1 || artist.length < 1
              begin
                lastfm_album = Scrobbler::Album.new(artist, album, :include_info => true)
              rescue
                # most likely there is no extended information avaiable
                begin
                  lastfm_album = Scrobbler::Album.new(artist, album)
                rescue => e
                  puts " **** ERROR: couldn't get album information: " + e.message
                end
              end

              unless lastfm_album.nil?
                cover_url  = lastfm_album.image_large
                
                unless cover_url.nil?
                  puts " **** Cover image found at: #{cover_url}"

                  # tmp image could be created
                  puts " **** Inserting new cover into file"
                  
                  # load image data
                  image_data = open(cover_url)
                  
                  cover = {
                    :id          => :APIC,
                    :mimetype    => image_data.content_type, 
                    :picturetype => 3,
                    :description => 'Cover',
                    :textenc     => 0,
                    :data        => image_data.read 
                  }
                  tag << cover

                  #save new cover
                  tag.update!

                  # update file processing counter
                  processed_files += 1

                  # new cover image saved
                  puts " ***** New cover image stored in file"
                  puts " ***** Number of mp3s tagged: #{processed_files}"
                else
                  puts " **** No cover url found, cannot insert cover image"
                end
              else
                puts " **** Couldn't get information from Last.fm"
              end
            else
              puts " **** Missing information in id3 tags. Cannot use for Last.fm"
            end
          else
            # cover already present
            puts " *** Cover art already present"
          end
        else
          puts " *** Tag could not be determined"
        end
        time_duration = Time.now - start_time
        puts " * Elapsed time: #{time_duration} seconds"
      end
    else
      puts "#{a} is not a directory"
    end
  end
else
  puts "missing arguments: please pass at least one directory path"
end
