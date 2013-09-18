#!/usr/bin/env ruby

# ENV['RAILS_ENV'] ||= 'development'
# require File.dirname(__FILE__) + '/../config/environment'
require 'digest/md5'
require 'csv'
require 'ftools'
require 'mediawiki-gateway/lib/media_wiki'

##########################
### image updater script by chris kim
### *run cron per minute (set in /etc/cron.minute)
### *runs in conjunction with customized gateway.rb from the mediagateway ruby gem
#########################
###################

##################
#UPDATES
#
#created 04262012
# - uses bots higher query limits to get images
#
#########################

#####################
#TODO : right now just rebuild the entire xml now... doesnt do anything with timestamp yet
##############

RAILS_ROOT = File.dirname(__FILE__)

$, = ""
 

#checks if wiki hook touched lastupdate and compare against last time script triggered
if (File.open('/www/wikem-server/last-file-upload').mtime > File.open('/www/wikem-server/lastran-imagescript').mtime)
        puts "A File has been uploaded "
        #get the difference in time since last update
        lastUpdateStamp = File.open('/www/wikem-server/lastran-imagescript').mtime
        timedifference = File.open('/www/wikem-server/last-file-upload').mtime - lastUpdateStamp
        puts "last file uploaded: #{timedifference} secs"
        #new mtime for lasttimescript ran placed after call to mw-gateway so as to avoid duplicate requests -> FileUtils.touch('/www/wikem-server/lastran-androidscript')
else
        #puts "No updates available, exiting..."
        exit
end














puts "trying to get images"

#starting to run script. Will use my mediawiki-gateway methods which will retreive data starting from a time parameter i pass into it
current_stamp = Time.now.to_i
#use time difference to make a timestamp with the difference 
  
#format the timestamp to be understandable by mediawiki api
#formatted_timestamp = current_stamp.strftime("%Y%m%d%H%M%S")

mw = MediaWiki::Gateway.new('http://www.wikem.org/w/api.php')
mw.login('robot','wikem-vona')

#images 
#TODO current do nothing with timestmap in future can use aiprop=timestamp
image_urls= mw.list_images(current_stamp) 

#the time in the info.XML will be written...NOT the last touched time
curr_time = Time.now
puts "#{curr_time.to_s}" #put the time into the logfile in var log cronminute
require 'rubygems'
require 'builder'
require 'nokogiri'
 

builder = Nokogiri::XML::Builder.new do |xml|
xml.api {
  xml.query {
    xml.allimages {
      image_urls.each do |o|
	xml.img(:url => o)
	#puts "added to xml #{o}"
	end
      
    }
  }
}
end
#puts builder.to_xml 


#save file
filename = 'copy-of-img-urls.xml'
#output = Nokogiri::XML::Document.new
#output = builder.to_xml
File.open( filename, 'w') {|f| f.write(builder.to_xml) }
File.copy(filename, "/www/dl.android.wikem.org/files/img-urls.xml")
puts "copied image url xml to ~~/files/img-urls.xml" 
