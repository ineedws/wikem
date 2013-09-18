#!/usr/bin/env ruby


# ENV['RAILS_ENV'] ||= 'development'
# require File.dirname(__FILE__) + '/../config/environment'
require 'digest/md5'
require 'csv'
require 'ftools'
require 'mediawiki-gateway/lib/media_wiki'

#####################################
###updater script by chris kim
### *run cron per minute (set in /etc/cron.minute)
### *runs in conjunction with customized gateway.rb from the mediagateway ruby gem
#########################

###########################
#UPDATES for v5 of script
##update 06072012
# -for memory and storage issues on android now 2 types of android db processed
#   	kept oritinal for content ->sit primarily on external storage
#	new slim db for memory to load without content
# -master sqlite db that works for php updater
#	..strangely, the FTS columns and table names used to make android behave correctly
#	arent recognized elsewhere, such as sqlite3 terminal or php
###########################

###older updates#######
##update 10102011
# - fix xml for old iphone (crash on empty category)
##update 09272011
# - fixes sqlite3 to finally use FTS table, now that recompiled sqlite3.c 
#    (#define SQLITE_ENABLE_COLUMN_METADATA and #define SQLITE_ENABLE_FTS3)
# - also reactivate user script now that fixed idiotic bug 
#
## update:09092011 
#  -uses freshly created Android db, with porter tokenizer
######################################

#########################
#in wiki's LocalSettings.php: 
# touches 'lastupdate' for content 
#       or 'last-user-created ' for new users
#when updated here in script
# script will touch 'lastran-androidscript' and/or 'lastran-userpagescript'
###########################
RAILS_ROOT = File.dirname(__FILE__)

#sets the  delimiter which default "" for ruby. (just in case... ) remember to change it back if u change!!!
$, = ""

#checks if wiki hook touched lastupdate and compare against last time script triggered
if (File.open('/www/wikem-server/lastupdate').mtime > File.open('/www/wikem-server/lastran-androidscript').mtime || File.open('/www/wikem-server/last-user-created').mtime > File.open('/www/wikem-server/lastran-userpagescript').mtime)
	puts "An update has been made to the wiki, updating mobile client db"
	#get the difference in time since last update
	lastUpdateStamp = File.open('/www/wikem-server/lastran-androidscript').mtime
	timedifference = File.open('/www/wikem-server/lastupdate').mtime - lastUpdateStamp
	puts "last updated: #{timedifference} secs"
	#new mtime for lasttimescript ran placed after call to mw-gateway so as to avoid duplicate requests -> FileUtils.touch('/www/wikem-server/lastran-androidscript')
else
	#puts "No updates available, exiting..."
	exit
end

######################################
# CUSTOM Classes
#
class Page
  attr_accessor :name, :folder, :content, :last_update, :author_name  
end
#user class to autocreate user namespace pages when new account created
class User
	attr_accessor :name, :realname, :custom1, :custom2
end
#
#######################################

#starting to run script. Will use my mediawiki-gateway methods which will retreive data starting from a time parameter i pass into it
current_stamp = Time.now.to_i
#use time difference to make a timestamp with the difference 
	#get_updates_up_until = Time.at(current_stamp - timedifference)
	get_updates_up_until = Time.at(lastUpdateStamp)

#format the timestamp to be understandable by mediawiki api
formatted_timestamp = get_updates_up_until.strftime("%Y%m%d%H%M%S")

mw = MediaWiki::Gateway.new('http://www.wikem.org/w/api.php')
mw.login('robot','wikem-vona')

#get 'newly created page' element of recent changes by using custom method in gateway.rb
newpage_names = mw.list_new(formatted_timestamp)
#get all page edits minus 'redirects' 
edited_page_names = mw.list_recent_changes(formatted_timestamp)
#get name of deleted pages
deleted_names = mw.list_deleted(formatted_timestamp)

#get moved: use list_moved_oldtitles and list_moved_newtitles which return arrays
old = mw.list_moved_oldtitles(formatted_timestamp)
new = mw.list_moved_newtitles(formatted_timestamp)

#now that we retreived pages, new mtime for last time the script ran is processed ( so as to avoid duplicate requests). we are good now. any changes whic take place however long remainder of script takes will still be processed on next cron cycle. thus, the efficiency of the rest of script won't matter as much as long as it is not unacceptilby slow-- would much rather the script be robust
FileUtils.touch('/www/wikem-server/lastran-androidscript')
#note: that if a new page was made the instant while retreiving these page names, problem. the lastupdate time will be before the lastranandroidscript and thus not trigger an update. luckily, easier to deal with missing edits than duplicates and end of script will deal with that

#the time in the info.XML will be written...NOT the last touched time
curr_time = Time.now
puts "#{curr_time.to_s}" #put the time into the logfile in var log cronminute
require 'rubygems'
require 'builder'
require 'nokogiri'
require 'sqlite3'

################################## 
#custom methods 
##################################

	#############################
	#custom method added to now parse out the image link and remove the base path
	#
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
	#
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
	###############################
	#custom method to make a userpage
	def makeUser()
		@users = []
			
	mw = MediaWiki::Gateway.new('http://www.wikem.org/w/api.php')
	mw.login('robot','wikem-vona')

		allusers = mw.list_all_users()
		counter = 0
		length = allusers.length
		iterations = length / 4

		counter.upto(iterations-1) do
			u = User.new
			u.name = allusers[counter]
			u.realname = allusers[counter+1]
			u.custom1 = allusers[counter+2]
			u.custom2 = allusers[counter+3]
			counter+=4
			@users << u
		end
	puts "creating pages"
		@users.each do |x|
			#puts "username is #{x.name}"
			#puts "realname is #{x.realname} #{x.custom1}"
			#puts "from #{x.custom2}"
			temp = "User:" + x.name
			content = x.realname + " " + x.custom1 + "." + "\n\n " + x.custom2 + "."
			temppage = mw.get(temp)
			#if page is nil then write the page
			if (temppage == nil)
				puts mw.create(temp, content, {:overwrite => true, :summary => 'autogenerated page'})
			else
				#puts "no page created for #{x.name}"
				end
		end
		
	end
#######################
#end of custom methods
#########################


#remove names of moved pages which have moved but have edits. otherwise will end up recreating the page as a 'lost' page
old.each do |o|
	if edited_page_names.include?(o)
		edited_page_names.delete(o)
		#puts "won't update old page #{o}"
	end
end
#similarly, iterate through new_pages to remove names of pages which have moved and don't need to be reassigned a redundant row or pageid. only leave truly new pages. 
new.each do |n|
	if newpage_names.include?(n)
		newpage_names.delete(n)
		#puts "won't create new/moved page #{n}"
	end
end
 
#merge the new and old arrays to a simplified hash
moved_names = Hash[old.zip(new)] # Ruby 1.8.7 and later. currently our wikem is 1.8.7
moved_names = Hash[*old.zip(new).flatten]
moved_names.each do|old,new|
#puts "moving from old to new: #{old}: #{new}"
end
		
#reference arrays of edits, new pages, and lost pages (ie. edits to pages which for reasons unknown are not in our database) 
@editpages = []
@newpages = []
@nilpages = []

#get edited page data for each unique page that was edited
if edited_page_names!=nil
edited_page_names.uniq!
	edited_page_names.each do |n|
	  #puts "Download page: #{n}"
	  page = Page.new
	  page.name = n
	  page.folder = mw.get_categories(n)
	#  page.content = mw.render(n)
	  rendered = mw.render(n)
	  page.content = image_linkparse(rendered)
	  page.last_update = current_stamp
	  page.author_name = 'WikEM'
	  @editpages << page
	end
end



#initiate the FTS updated db for android which includes definition
 db = SQLite3::Database.new( "db-v3.db" )
 db.transaction
#initiate the non-FTS updated db for server php script
 dbPhp = SQLite3::Database.new( "db-for-php.db" )
 dbPhp.transaction
#initiate the 'title-only' FTS db for android. NO (null) DEFINITION column
 dbTitle = SQLite3::Database.new( "db-v4-slim.db" )
 dbTitle.transaction
 
############################################
#SQLITE schema of db created by android os 
# sqlite> .schema
# CREATE VIRTUAL TABLE FTSdictionary USING fts3 
#	(suggest_text_1 CONSTRAINT UNIQUE ON CONFLICT IGNORE , DEFINITIONS, suggest_text_2, WIKEM_URI, FAVORITE, LAST_UPDATE);
#
#CREATE TABLE FTSdictionary_content(  docid INTEGER PRIMARY KEY,c0suggest_text_1,     c1DEFINITIONS, c2suggest_text_2, c3WIKEM_URI, c4FAVORITE, c5LAST_UPDATE);
#CREATE TABLE FTSdictionary_segdir(  level integer,  idx integer,  start_block in    teger,  leaves_end_block integer,  end_block integer,  root blob,  primary key(l    evel, idx));
#CREATE TABLE FTSdictionary_segments(  blockid INTEGER PRIMARY KEY,  block blob);
#CREATE TABLE android_metadata (locale TEXT);
#
# note, previously worked with 'FTSdictionary_content' table
# NOW, correctly working with 'FTSdictionary' which is actually a fts3 (full text search...ie. faster) VIRTUAL table
#  (also replaced column titles 'c0suggest_text_1' with 'suggest_text_1' etc..) 
#
#
#
#For the php script
#update (6/2012) :  turns out that what works for the android is not working for normal queries
#                   to make a php script which can query a timestamp, will need to work in a  'non fts' way with database
#					ie. use 'FTSdictionary' in leiu of 'FTSdictionary_content' table
#							and
#						use 'c0suggest_text_1' in leiu of 'suggest_text_1' columns
############
  
 

 
 #opening the nokogiri xml doc
#buffer = File.open("/www/dl.android.wikem.org/db-update.xml",'r').read
buffer = File.open("copy-of-lastmadedb.xml",'r').read
doc = Nokogiri::XML(buffer)
  
  
#process moved pages
#moved pages go first, then we can add to the list of newpages pages which need to be made in strange cases where a page was created and immediately moved to a new title. 
#moved pages before edits obviously as new_title of moved page might have an edit.
if (moved_names!=nil)
	moved_names.each do |old, new|
		#puts "moving from old to new: #{old}: #{new}"
		#fist change sqlite, the new title_name into the row of old title
		db.execute("UPDATE FTSdictionary SET suggest_text_1 =  :newtitle, LAST_UPDATE = :lastupdate WHERE suggest_text_1 = :oldtitle;", 
		"oldtitle" => old,
		"newtitle" => new,
		"lastupdate" => curr_time.to_i)
		dbTitle.execute("UPDATE FTSdictionary SET suggest_text_1 =  :newtitle, LAST_UPDATE = :lastupdate WHERE suggest_text_1 = :oldtitle;", 
		"oldtitle" => old,
		"newtitle" => new,
		"lastupdate" => curr_time.to_i)
		dbPhp.execute("UPDATE FTSdictionary_content SET c0suggest_text_1 =  :newtitle, c5LAST_UPDATE = :lastupdate WHERE c0suggest_text_1 = :oldtitle;", 
		"oldtitle" => old,
		"newtitle" => new,
		"lastupdate" => curr_time.to_i)
	
	
	#now XML part. change attribute name of page as well as lastupdate time
	pID = "page[@id=\"" + old.downcase.gsub(/\s/,'_') + "\"]" 
	newname = new.downcase.gsub(/\s/,'_')
	#puts "trying to change the moved page #{pID}"
	page = doc.at_css("#{pID}")
	#in weird case where moved page isn't created create the page
	if (page == nil)
		#create the page bc it's not there. add it to list of newpages
		newpage_names << new
		deleted_names << old
		puts "ALERT: can't move. will have to download new"
	else
	#otherwise if it already exists... process the xml
		page.attributes["id"].value = newname
			page.children.each do |c|		
				if(c.name == "name")
					c.content = new
					end
				if (c.name == "last_update")
					#puts "trying to replace update"
					c.content = curr_time.to_i			
					end						
			end
			 
		end
		puts "MOVED #{old}"
	end
end
	
  
# newly made pages
if newpage_names!=nil
newpage_names.uniq!
	 newpage_names.each do |n|
	  puts "Download NEW page: #{n}"
	  page = Page.new
	  page.name = n
	  page.folder = mw.get_categories(n)
	  #page.content = mw.render(n)
	  rendered = mw.render(n)
	  page.content = image_linkparse(rendered)
	  page.last_update = current_stamp
	  page.author_name = 'WikEM'
	  @newpages << page
	end


#build the new pages
@newpages.each do |n|
	#first make the SQLite insert. luckily it automatically increments the _rowid that android needs to be in sequential order... unlike deletions.
	zero = Integer('0')
	if n.folder.first!=nil
		tempCategory = getCatAsString(n.folder, " ")

		db.execute("INSERT into FTSdictionary (suggest_text_1, DEFINITIONS, suggest_text_2, FAVORITE, LAST_UPDATE) VALUES (:name, :content, :category, :favorite, :lastupdate)", 
		"name" => n.name,
		"content" => n.content,
		#"category" => n.folder.first,
		"category" => tempCategory,
		"favorite" => zero,
		"lastupdate" => n.last_update)
		dbTitle.execute("INSERT into FTSdictionary (suggest_text_1, suggest_text_2, FAVORITE, LAST_UPDATE) VALUES (:name, :category, :favorite, :lastupdate)", 
		"name" => n.name,
		#"content" => n.content,
		#"category" => n.folder.first,
		"category" => tempCategory,
		"favorite" => zero,
		"lastupdate" => n.last_update)
		dbPhp.execute("INSERT into FTSdictionary_content (c0suggest_text_1, c1DEFINITIONS, c2suggest_text_2, c4FAVORITE, c5LAST_UPDATE) VALUES (:name, :content, :category, :favorite, :lastupdate)", 
		"name" => n.name,
		"content" => n.content,
		#"category" => n.folder.first,
		"category" => tempCategory,
		"favorite" => zero,
		"lastupdate" => n.last_update)
	else
		db.execute("INSERT into FTSdictionary (suggest_text_1, DEFINITIONS, FAVORITE, LAST_UPDATE) VALUES (:name, :content, :favorite, :lastupdate)", 
		"name" => n.name,
		"content" => n.content,
		"favorite"=> zero,
		"lastupdate" => n.last_update)	
		dbTitle.execute("INSERT into FTSdictionary (suggest_text_1, FAVORITE, LAST_UPDATE) VALUES (:name, :favorite, :lastupdate)", 
		"name" => n.name,
		#"content" => n.content,
		"favorite"=> zero,
		"lastupdate" => n.last_update)	
		dbPhp.execute("INSERT into FTSdictionary_content (c0suggest_text_1, c1DEFINITIONS, c4FAVORITE, c5LAST_UPDATE) VALUES (:name, :content, :favorite, :lastupdate)", 
		"name" => n.name,
		"content" => n.content,
		"favorite"=> zero,
		"lastupdate" => n.last_update)	
	end
	
	#now do XML part
	pID =  n.name.downcase.gsub(/\s/,'_')  
	puts "MAKING new page: #{pID}"
	pages = doc.at_css("pages")
	#build new child nodes and attach to parent node
		new_node = doc.create_element "page"
		new_node['id'] = pID
			name = doc.create_element"name"
			name.content = n.name
			name.parent = new_node
			
			content = doc.create_element "content"
			#content.inner_html = n.content
			content.content = n.content
			content.parent = new_node
			
			#sometimes there is no category. (previously didn't even make folder tags, crashed old iphone)
			if(n.folder.first != nil)
				folder = doc.create_element "folder"
###################################
				folder.content = getCatAsString(n.folder, "|")
				folder.parent = new_node			
			else
			#ie. no category for this new page. just make blank folder tag regardless
				folder = doc.create_element "folder"
				folder.content = " "
				folder.parent = new_node
			end
			
			lu = doc.create_element "last_update"
			lu.content = n.last_update
			lu.parent = new_node
			
			a = doc.create_element "author"
			a.content = n.author_name
			a.parent = new_node
			
		new_node.parent = pages
	end
end 	

 
#make edits  
if !@editpages.nil?
@editpages.each do |p| 	 
	#first update the sqlite for android
		if (p.folder.first != nil)
		tempCategory = getCatAsString(p.folder, " ")
		else
		tempCategory = " "
		end
	db.execute("UPDATE FTSdictionary SET DEFINITIONS =  :content, LAST_UPDATE = :lastupdate ,  suggest_text_2 = :categories WHERE suggest_text_1 = :name;", 
	"name" => p.name,
	"content" => p.content,
	"lastupdate" => p.last_update,
	"categories" => tempCategory)
	dbTitle.execute("UPDATE FTSdictionary SET LAST_UPDATE = :lastupdate ,  suggest_text_2 = :categories WHERE suggest_text_1 = :name;", 
	"name" => p.name,
	#"content" => p.content,
	"lastupdate" => p.last_update,
	"categories" => tempCategory)
	dbPhp.execute("UPDATE FTSdictionary_content SET c1DEFINITIONS =  :content, c5LAST_UPDATE = :lastupdate ,  c2suggest_text_2 = :categories WHERE c0suggest_text_1 = :name;", 
	"name" => p.name,
	"content" => p.content,
	"lastupdate" => p.last_update,
	"categories" => tempCategory)
	
	#now XML part
	pID = "page[@id=\"" + p.name.downcase.gsub(/\s/,'_') + "\"]" 
	#puts "trying to replace #{pID}"
	page = doc.at_css("#{pID}")
		if (page != nil)
			hasFolder = false
			page.children.each do |c|
			#if we are to change all elements, a switch better. but practically only needs to change content&time
				if (c.name == "content")
					#puts "trying to replace content"
					c.content = p.content
					end
				if (c.name == "last_update")
					#puts "trying to replace update"
					c.content = p.last_update
					end	
				#a folder may or maynot even exist...
				if (c.name == "folder")
					hasFolder = true
					c.content = getCatAsString(p.folder,"|")
					end
			end
#########################ck making a new folder 
			if (hasFolder == false && p.folder.first != nil)
				folder = doc.create_element "folder"
 				folder.content = getCatAsString(p.folder, "|")
				folder.parent = page	
			end
			puts "EDITED #{pID}"
		else
			#no reason why it should be nil.. store these oddballs here for now to do something with later. add p to the array of nilpages and create
			@nilpages << p
		end
		
	end

 end  
 
 
 #recreate lost pages captured by @nilpages[] in this script, ie. edits made to a page which doesn't even exist for whatever reason.

@nilpages.each do |n|
	#first make the SQLite insert
	zero = Integer('0')
	if (n.folder.first!=nil)
		tempCategory =getCatAsString(n.folder, " ")
		else
		tempCategory = " "
		end
		db.execute("INSERT into FTSdictionary (suggest_text_1, DEFINITIONS, suggest_text_2, FAVORITE, LAST_UPDATE) VALUES (:name, :content, :category, :favorite, :lastupdate)", 
		"name" => n.name,
		"content" => n.content,
		"category" => tempCategory,
		"favorite" => zero,
		"lastupdate" => n.last_update)
		dbTitle.execute("INSERT into FTSdictionary (suggest_text_1, suggest_text_2, FAVORITE, LAST_UPDATE) VALUES (:name, :category, :favorite, :lastupdate)", 
		"name" => n.name,
		#"content" => n.content,
		"category" => tempCategory,
		"favorite" => zero,
		"lastupdate" => n.last_update)
		dbPhp.execute("INSERT into FTSdictionary_content (c0suggest_text_1, c1DEFINITIONS, c2suggest_text_2, c4FAVORITE, c5LAST_UPDATE) VALUES (:name, :content, :category, :favorite, :lastupdate)", 
		"name" => n.name,
		"content" => n.content,
		"category" => tempCategory,
		"favorite" => zero,
		"lastupdate" => n.last_update)
	#else
	#	db.execute("INSERT into FTSdictionary (suggest_text_1, DEFINITIONS, FAVORITE, LAST_UPDATE) VALUES (:name, :content, :favorite, :lastupdate)", 
	#	"name" => n.name,
	#	"content" => n.content,
	#	"favorite"=> zero,
	#	"lastupdate" => n.last_update)	
	#end
	
	
	###############
	#now do XML part
	pID =  n.name.downcase.gsub(/\s/,'_')  
	puts "RESTORED lost page: #{pID}"
	pages = doc.at_css("pages")
	#build new child nodes and attach to parent node
		new_node = doc.create_element "page"
		new_node['id'] = pID
			name = doc.create_element"name"
			name.content = n.name
			name.parent = new_node
			
			content = doc.create_element "content"
			#content.inner_html = n.content
			content.content = n.content
			content.parent = new_node
			
			#sometimes there is no category.
			if(n.folder.first != nil)
				folder = doc.create_element "folder"
				folder.content = getCatAsString(n.folder, "|")
				folder.parent = new_node
			else
				folder = doc.create_element "folder"
				folder.content = " "
				folder.parent = new_node
			end
			
			lu = doc.create_element "last_update"
			lu.content = n.last_update
			lu.parent = new_node
			
			a = doc.create_element "author"
			a.content = n.author_name
			a.parent = new_node
			
		new_node.parent = pages
	end
  	
 
#Lastly, remove deleted pages....remember. app previously crashed and behave werid when just deleted rows. i htink android needs the FTS rowid updated sequentially..cannot just delete a row. will  pass a delete token in special junk row 'WIKEM_URI' and delete from app. 
deleteTokenForAndroid = "DELETE"

if (deleted_names!=nil)	
	 deleted_names.each do |x|
	 #first update the sqlite for android
		#db.execute("DELETE FROM FTSdictionary WHERE suggest_text_1 = :name", 
		#"name" => x)
		db.execute("UPDATE FTSdictionary SET WIKEM_URI = :deletetoken, DEFINITIONS = :blank WHERE suggest_text_1 = :name;", 
		"name" => x,
		"blank" => deleteTokenForAndroid,
		"deletetoken" => deleteTokenForAndroid)
		dbTitle.execute("UPDATE FTSdictionary SET WIKEM_URI = :deletetoken  WHERE suggest_text_1 = :name;", 
		"name" => x,
		#"blank" => deleteTokenForAndroid,
		"deletetoken" => deleteTokenForAndroid)
		dbPhp.execute("UPDATE FTSdictionary_content SET c3WIKEM_URI = :deletetoken, c1DEFINITIONS = :blank WHERE c0suggest_text_1 = :name;", 
		"name" => x,
		"blank" => deleteTokenForAndroid,
		"deletetoken" => deleteTokenForAndroid)
		
	 #now XML part
		pID = "page[@id=\"" + x.downcase.gsub(/\s/,'_') + "\"]" 
		pagetodelete = doc.at_css("#{pID}")
		#need this error check to avoid errors with nil. in case the old database.xml doesn't even have an entry to delte, eg/ if someone makes a page and then deletes immediately...in that case the page won't even be removed from the list of "new" pages
		if(pagetodelete!=nil)
			pagetodelete.remove
			puts "DELETED #{pID}"
			end

	end
end


#################################################
#END of work. Commit Transactions###########
db.commit
if db.closed?()
#do nothing, but avoid catastrophie by closing an already closed db
else
db.close
end

dbTitle.commit
if dbTitle.closed?()
#do nothing, but avoid catastrophie by closing an already closed db
else
dbTitle.close
end

dbPhp.commit
if dbPhp.closed?()
#do nothing, but avoid catastrophie by closing an already closed db
else
dbPhp.close
end
#end commiting transactions
#####################



#write these XML changes to file.
puts "writing to ~~/files/db-update.xml"
File.open('/www/dl.android.wikem.org/files/db-update.xml','w') {|f| doc.write_xml_to f}
#keep the copy for the script to open next time
File.copy("/www/dl.android.wikem.org/files/db-update.xml", "copy-of-lastmadedb.xml")
#copy db to location needed for v2 of wikem
File.copy("/www/dl.android.wikem.org/files/db-update.xml", "/www/dl.android.wikem.org/database.xml") 

# write info for the new info file, for android number of files no longer matters
info_file = File.dirname(__FILE__) + "/public/info.xml"
fp_xml = File.open(info_file, 'w')
xml_info = Builder::XmlMarkup.new(:target => fp_xml)
xml_info.instruct!
xml_info.root {
  xml_info.lastupdate("epoch" => curr_time.to_i)
  xml_info.size("byte" => File.size("db-v3.db"), "num" => @editpages.size)
}
fp_xml.close

###############################################################################
#Copying stuff
############ into the public directory for client apps to grab
#################
File.copy(info_file, "/www/dl.android.wikem.org/files/info.xml")
puts "copied info file to ~~/files/info.xml"

#############################################
### old info file for old iphone app ( filesize of xml different)
############################################
 info_file2 = File.dirname(__FILE__) + "/public/info2.xml"
fp_xml = File.open(info_file2, 'w')
xml_info = Builder::XmlMarkup.new(:target => fp_xml)
xml_info.instruct!
xml_info.root {
  xml_info.lastupdate("epoch" => curr_time.to_i)
  xml_info.size("byte" => File.size("copy-of-lastmadedb.xml"), "num" => @editpages.size)
}
fp_xml.close

#copy info to old v2 location for old iphones
File.copy(info_file2, "/www/dl.android.wikem.org/info.xml")
puts "ALSO copy files for v2-iphone at dl.wikem.org/database.xml and info.xml"

#copy the db file to directory for dl by android
File.copy("db-v3.db", "/www/dl.android.wikem.org/files/android_db")
puts "copied the db to ~~/files/android_db"
File.copy( "db-for-php.db", "/www/dl.android.wikem.org/files/phpdb.db")
puts "copied the php db"
File.copy( "db-v4-slim.db", "/www/dl.android.wikem.org/files/android_dbslim")

#end copying stuff
####################################################


 ## in scenario where update and new user created, can check for new user here after all the crud is done
if (File.open('/www/wikem-server/last-user-created').mtime > File.open('/www/wikem-server/lastran-userpagescript').mtime)
		puts "a new user account was made"
		makeUser()
		FileUtils.touch('/www/wikem-server/lastran-userpagescript')
	end
##all done
