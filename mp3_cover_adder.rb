require 'rubygems'
require 'id3lib'

# Load a tag from a file
tag = ID3Lib::Tag.new(:file)

# get music information 
title = tag.title
album = tag.album

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
