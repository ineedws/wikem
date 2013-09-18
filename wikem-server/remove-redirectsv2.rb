#!/usr/bin/env ruby


# ENV['RAILS_ENV'] ||= 'development'
# require File.dirname(__FILE__) + '/../config/environment'
require 'digest/md5'
require 'csv'
require 'ftools'
require 'mediawiki-gateway/lib/media_wiki'

################################
### remove ALL redirects if not already removed..
### like other scripts, in this directory contains the two source files
####copy-of-lastmadedb.xml and db.db
#################################
RAILS_ROOT = File.dirname(__FILE__)

class Page
  attr_accessor :name, :folder, :content, :last_update, :author_name
  
end
 
 
puts "Downloading WikEM Data - removing redirects"

mw = MediaWiki::Gateway.new('http://www.wikem.org/w/api.php')
mw.login('robot','wikem-vona')

page_names = mw.list_redirects('')
#curr_time used to build the info file
curr_time = Time.now

 
require 'rubygems'
require 'builder'
require 'nokogiri'
require 'sqlite3'


#testing sqlite for ruby
 db = SQLite3::Database.new( "db.db" )
 db.transaction
#saving the nokogiri xml doc
buffer = File.open("copy-of-lastmadedb.xml",'r').read
doc = Nokogiri::XML(buffer)
 
 deleteTokenForAndroid = 'DELETE'
#now remove deleted pages
if (page_names!=nil)	
	 page_names.each do |x|
	 #first update the sqlite for android
		#db.execute("DELETE FROM FTSdictionary_content WHERE c0suggest_text_1 = :name", 
		#"name" => x.name)
		 
		db.execute("UPDATE FTSdictionary_content SET c3WIKEM_URI = :deletetoken, c1DEFINITIONS = :blank  WHERE c0suggest_text_1 = :name;", 
		"name" => x,
		"blank" => deleteTokenForAndroid,
		"deletetoken" => deleteTokenForAndroid)
		
		
	 #now XML part
		pID = "page[@id=\"" + x.downcase.gsub(/\s/,'_') + "\"]" 
		puts "trying to DELETE #{pID}"
		pagetodelete = doc.at_css("#{pID}")
		#need this error check to avoid errors with nil. in case the old database.xml doesn't even have an entry to delte, eg/ if someone makes a page and then deletes immediately...in that case the page won't even be removed from the list of "new" pages
		if(pagetodelete!=nil)
			pagetodelete.remove
			end

	end
end
db.commit

#write these XML changes to file.
puts "writing to ~~/files/db-update.xml"
File.open('/www/dl.android.wikem.org/files/db-update.xml','w') {|f| doc.write_xml_to f}
File.copy("/www/dl.android.wikem.org/files/db-update.xml", "copy-of-lastmadedb.xml")


# write info for the new info file, for android number of files no longer matters
#for iphone?
info_file = File.dirname(__FILE__) + "/public/info.xml"
fp_xml = File.open(info_file, 'w')
xml_info = Builder::XmlMarkup.new(:target => fp_xml)
xml_info.instruct!
xml_info.root {
  xml_info.lastupdate("epoch" => curr_time.to_i)
  xml_info.size("byte" => File.size("db.db"), "num" => page_names.size)
}
fp_xml.close

File.copy(info_file, "/www/dl.android.wikem.org/files/info.xml")
puts "copied info file to ~~/files/info.xml"

#copy the db file to directory for dl by phone
File.copy("db.db", "/www/dl.android.wikem.org/files/android_db")
puts "copied the db to ~~/files/android_db"
 
 