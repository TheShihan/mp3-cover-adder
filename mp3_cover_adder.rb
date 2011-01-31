#!/usr/bin/env ruby

require 'id3lib'
require 'open-uri'
require 'rails'
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
              begin
                album = Scrobbler::Album.new(artist, album, :include_info => true)
              rescue
                album = Scrobbler::Album.new(artist, album)
              end

              cover_url  = album.image_large
              
              unless cover_url.nil?
                puts "Cover image found at: #{cover_url}"

                # tmp image could be created
                puts " **** Inserting new cover into file"
                
                content_type = 'image/jpg'

                open(cover_url) do |tmp_cover_file|
                  content_type_src = tmp_cover_file.content_type
                  content_type = content_type_src unless content_type_src.nil?
                end
                
                image = open(cover_url).read
                
                cover = {
                  :id          => :APIC,
                  :mimetype    => content_type, 
                  :picturetype => 3,
                  :description => 'Cover',
                  :textenc     => 0,
                  :data        => image 
                }
                tag << cover

                #save new cover
                tag.update!

                # update file processing counter
                processed_files += 1

                # new cover image saved
                puts " ***** New cover image stored in file"
              end
            else
              puts " **** Album information missing. Cannot use for Last.fm"
            end
          else
            # cover already present
            puts " *** Cover art already present"
          end
        else
          puts " *** Tag could not be determined"
        end
      end
        puts "   Number of mp3s tagged: #{processed_files}"
    else
      puts "#{a} is not a directory"
    end
  end
else
  puts "missing arguments: please pass at least one directory path"
end
