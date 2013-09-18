#!/usr/bin/env ruby


# ENV['RAILS_ENV'] ||= 'development'
# require File.dirname(__FILE__) + '/../config/environment'
require 'digest/md5'
require 'csv'
require 'ftools'
require 'mediawiki-gateway/lib/media_wiki'


RAILS_ROOT = File.dirname(__FILE__)

$, = ""
#checks if wiki hook touched lastupdate and compare against last time script triggered
if File.open('/www/wikem-server/lastupdate').mtime > File.open('/www/wikem-server/lastran-androidscript').mtime
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


class Page
  attr_accessor :name, :folder, :content, :last_update, :author_name  
end

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
# dollar sign gives predefined ruby global variable
#$, is RUBY default field separator for print and Array#join... "", ie nothing	
 #set the  delimiter which default "" for ruby. remember to change it back!!!
##if forget then all timestamps  will output separated and both apps can't update
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



#testing sqlite for ruby
 db = SQLite3::Database.new( "db.db" )
 db.transaction
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
		db.execute("UPDATE FTSdictionary_content SET c0suggest_text_1 =  :newtitle, c5LAST_UPDATE = :lastupdate WHERE c0suggest_text_1 = :oldtitle;", 
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
		db.execute("INSERT into FTSdictionary_content (c0suggest_text_1, c1DEFINITIONS, c2suggest_text_2, c4FAVORITE, c5LAST_UPDATE) VALUES (:name, :content, :category, :favorite, :lastupdate)", 
		"name" => n.name,
		"content" => n.content,
		#"category" => n.folder.first,
		"category" => getCatAsString(n.folder, " "),
		"favorite" => zero,
		"lastupdate" => n.last_update)
	else
		db.execute("INSERT into FTSdictionary_content (c0suggest_text_1, c1DEFINITIONS, c4FAVORITE, c5LAST_UPDATE) VALUES (:name, :content, :favorite, :lastupdate)", 
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
			
			#sometimes there is no category. (this doesn't even bother making folder tags)
			if(n.folder.first != nil)
				folder = doc.create_element "folder"
###################################
				folder.content = getCatAsString(n.folder, "|")
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
	db.execute("UPDATE FTSdictionary_content SET c1DEFINITIONS =  :content, c5LAST_UPDATE = :lastupdate ,  c2suggest_text_2 = :categories WHERE c0suggest_text_1 = :name;", 
	"name" => p.name,
	"content" => p.content,
	"lastupdate" => p.last_update,
	"categories" => getCatAsString(p.folder, " "))
	
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
		db.execute("INSERT into FTSdictionary_content (c0suggest_text_1, c1DEFINITIONS, c2suggest_text_2, c4FAVORITE, c5LAST_UPDATE) VALUES (:name, :content, :category, :favorite, :lastupdate)", 
		"name" => n.name,
		"content" => n.content,
		"category" => n.folder.first,
		"favorite" => zero,
		"lastupdate" => n.last_update)
	else
		db.execute("INSERT into FTSdictionary_content (c0suggest_text_1, c1DEFINITIONS, c4FAVORITE, c5LAST_UPDATE) VALUES (:name, :content, :favorite, :lastupdate)", 
		"name" => n.name,
		"content" => n.content,
		"favorite"=> zero,
		"lastupdate" => n.last_update)	
	end
	
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
				folder.content = n.folder.first
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
  	
 
#Lastly, remove deleted pages....remember. android needs the FTS rowid updated sequentially..cannot just delete a row. will  pass a delete token in special junk row 'WIKEM_URI' and delete from app. 
deleteTokenForAndroid = "DELETE"

if (deleted_names!=nil)	
	 deleted_names.each do |x|
	 #first update the sqlite for android
		#db.execute("DELETE FROM FTSdictionary_content WHERE c0suggest_text_1 = :name", 
		#"name" => x)
		db.execute("UPDATE FTSdictionary_content SET c3WIKEM_URI = :deletetoken, c1DEFINITIONS = :blank WHERE c0suggest_text_1 = :name;", 
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
db.commit

#write these XML changes to file.
puts "writing to ~~/files/db-update.xml"
File.open('/www/dl.android.wikem.org/files/db-update.xml','w') {|f| doc.write_xml_to f}
#keep the copy for the script to open next time
File.copy("/www/dl.android.wikem.org/files/db-update.xml", "copy-of-lastmadedb.xml")
 

# write info for the new info file, for android number of files no longer matters
#for iphone?
info_file = File.dirname(__FILE__) + "/public/info.xml"
fp_xml = File.open(info_file, 'w')
xml_info = Builder::XmlMarkup.new(:target => fp_xml)
xml_info.instruct!
xml_info.root {
  xml_info.lastupdate("epoch" => curr_time.to_i)
  xml_info.size("byte" => File.size("db.db"), "num" => @editpages.size)
}
fp_xml.close

File.copy(info_file, "/www/dl.android.wikem.org/files/info.xml")
puts "copied info file to ~~/files/info.xml"

#copy the db file to directory for dl by phone
File.copy("db.db", "/www/dl.android.wikem.org/files/android_db")
puts "copied the db to ~~/files/android_db"
 
  
