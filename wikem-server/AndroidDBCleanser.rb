#!/usr/bin/env ruby


# ENV['RAILS_ENV'] ||= 'development'
# require File.dirname(__FILE__) + '/../config/environment'
require 'digest/md5'
require 'csv'
require 'ftools'
require 'mediawiki-gateway/lib/media_wiki'

#####################################
# script by chris kim
#run manually to rebuild updates to some arbitrary time.
# gets newly made Android sqlite DB made from the old-xml-script and cleanses it for use
# marks redirected pages in wikemURI column 
# leaves redirected content alone (previously all content wiped as deleted)
# 	(those pages begin as ' <ol><li>REDIRECT ' and just link to another page)
# deletes those pages otherwise 
#* **actually...the db built this way doesnt even have deleted pages.. redirects only
#
#
######################################

RAILS_ROOT = File.dirname(__FILE__)

#sets the  delimiter which default "" for ruby. remember to change it back if u change!!!
$, = ""

current_stamp = Time.now.to_i
#arbitrary 2 years seconds
delta_time = Time.at(current_stamp - 62899200)
arbitrarytime = delta_time.strftime("%Y%m%d%H%M%S")



class Page
  attr_accessor :name, :folder, :content, :last_update, :author_name  
end

 
#format the timestamp to be understandable by mediawiki api
formatted_timestamp = arbitrarytime

mw = MediaWiki::Gateway.new('http://www.wikem.org/w/api.php')
mw.login('robot','wikem-vona')
 
 #redirected pages
 redirected_names = mw.list_redirects('')

#get name of deleted pages
deleted_names = mw.list_deleted(formatted_timestamp)
 

#the time in the info.XML will be written...NOT the last touched time
curr_time = Time.now
puts "#{curr_time.to_s}" #put the time into the logfile in var log cronminute
require 'rubygems'
require 'builder'
require 'nokogiri'
require 'sqlite3'

###################################################
#custom methods added to now parse out the image link and remove the base path

def image_linkparse(content)
	doc = Nokogiri::HTML(content)
	#why didn't HTML.fragment work?...
	linkchanged = false
	doc.xpath('//a/img').each do |img|
		src = img.attributes["src"].value 
		puts "full src of img tag is #{src}"
		filename = File.basename(src)
		puts "file name is #{filename}"
		img.attributes["src"].value = filename
		#puts "after link change: #{content}"	
		linkchanged = true
	end
	if(linkchanged == true)
		bodynode = doc.css('body')
		#don't want null pointer but shouldn't ever be nil as loading nokogiri as HTML generates a proper HTML doc includeing <!doctype, <html>, and <body>
		if( bodynode != nil )
			temp = bodynode.inner_html()		
			#puts "now string is #{temp}"
			return temp
		else 
			puts "error parsing the image links"
			return content
		end
	else
		return content
	end
end
##############################################
#custom method to create appropriate string from an array
def getCatAsString(array, delimiter)
	 #set the  delimiter which default "" for ruby. remember to change it back!!!
	if(array.length > 1)
	 $, = "#{delimiter}"
	 s = array.to_s
	 $, = ""
	 puts "categories are #{s}"
	 return s
	end
	if array.empty?
		return ""
	end
	return array.first
end

  

#testing sqlite for ruby
 db = SQLite3::Database.new( "db-v3.db" )
 db.transaction
#opening the nokogiri xml doc
#buffer = File.open("/www/dl.android.wikem.org/db-update.xml",'r').read
buffer = File.open("copy-of-lastmadedb.xml",'r').read
doc = Nokogiri::XML(buffer)
  
  #in future can have separate actions for redirect..
    redirectTokenForAndroid = 'DELETE'
#now remove deleted pages
if (redirected_names!=nil)	
	 redirected_names.each do |z|
	 puts "redirecting #{z}"
	 #first update the sqlite for android
		#db.execute("DELETE FROM FTSdictionary_content WHERE c0suggest_text_1 = :name", 
		#"name" => z.name)
		  
		db.execute("UPDATE FTSdictionary_content SET c3WIKEM_URI = :deletetoken WHERE c0suggest_text_1 = :name", 
		"name" => z,
		"deletetoken" => redirectTokenForAndroid)
		 
	end
end
    
     
db.commit
 db.close
  
#copy the db file to directory for dl by phone
#File.copy("db.db", "/www/dl.android.wikem.org/files/android_db")
File.copy("db.db", "/www/dl.android.wikem.org/files/test2_db")

puts "copied the db to ~~/files/test_db"
 
  