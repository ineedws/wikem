#!/usr/bin/env ruby


# ENV['RAILS_ENV'] ||= 'development'
# require File.dirname(__FILE__) + '/../config/environment'
require 'digest/md5'
require 'csv'
require 'ftools'
 
#####################################
###one time fix categories 101011
###parse all of xml and if no folder tag... jsut add a bank one
### OR, use mw gateway get all categories (slow) and iterate all and fix original script
######################################

RAILS_ROOT = File.dirname(__FILE__)

#sets the  delimiter which default "" for ruby. remember to change it back if u change!!!
$, = ""

require 'rubygems'
require 'nokogiri'

buffer = File.open("copy-of-lastmadedb.xml",'r').read
doc = Nokogiri::XML(buffer)
#doc.at_css('page').each do |page|
doc.css('page').each do |page|
	hasFolder = false
	page.children.each do |c|
		if (c.name == "folder")
			puts "HAS FOLDER"
			hasFolder = true					
			end
	end
	#before go to next page. if page don't have folder
	if (hasFolder == false)
			folder = doc.create_element "folder"
 			folder.content = " "
			folder.parent = page	
			puts "added folder <folder></folder>"
			end			 
end
##ok now save file

puts "writing to ~~/files/db-update.xml"
File.open('/www/dl.android.wikem.org/files/db-update.xml','w') {|f| doc.write_xml_to f}
#keep the copy for the script to open next time
File.copy("/www/dl.android.wikem.org/files/db-update.xml", "copy-of-lastmadedb.xml")
#copy db to location needed for v2 of wikem
File.copy("/www/dl.android.wikem.org/files/db-update.xml", "/www/dl.android.wikem.org/database.xml") 

