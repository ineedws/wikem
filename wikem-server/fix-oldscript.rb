#!/usr/bin/env ruby


# ENV['RAILS_ENV'] ||= 'development'
# require File.dirname(__FILE__) + '/../config/environment'
require 'digest/md5'
require 'csv'
require 'ftools'
require 'mediawiki-gateway/lib/media_wiki'

################################
### 09/16/2011 ck
#fix db made from the oldscript (this version also changes categories for android db)
#1)remove ALL redirects 
#2)get all categories and fix (call mw.get_categories(n))
#3) fix image links (image_linkparse)
#################################
RAILS_ROOT = File.dirname(__FILE__)

class Page
  attr_accessor :name, :folder, :content, :last_update, :author_name
  
end
 
 
puts "Fixing version1 XML to v3 (images, and multi categories)"

mw = MediaWiki::Gateway.new('http://www.wikem.org/w/api.php')
mw.login('robot','wikem-vona')

redirpage_names = mw.list_redirects('')
#curr_time used to build the info file
curr_time = Time.now

 
require 'rubygems'
require 'builder'
require 'nokogiri'
require 'sqlite3'


#testing sqlite for ruby
 db = SQLite3::Database.new( "db-v3.db" )
 db.transaction
#saving the nokogiri xml doc
buffer = File.open("copy-of-lastmadedb.xml",'r').read
doc = Nokogiri::XML(buffer)
 
 #now remove deleted pages
if (redirpage_names!=nil)	
	 redirpage_names.each do |x|
	 #first update the sqlite for android
	 #DO NOTHING. can leave the redir's there
		
		
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

####ok now redirects done. now fix rest... iterate through all pages

page_names = mw.list('')

@pages = []
page_names.each do |n|
 # puts "Download page: #{n}"
  page = Page.new
  page.name = n
  page.folder = mw.get_categories(n)
  #page.content = mw.render(n)
  #page.last_update = current_stamp
  #page.author_name = 'WikEM'
  @pages << page
end


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
##########end of custom methods##########

@pages.each do|p|
	#first update the sqlite for android
	db.execute("UPDATE FTSdictionary_content SET c2suggest_text_2 = :categories WHERE c0suggest_text_1 = :name;", 
	"name" => p.name,
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
					newcontent = image_linkparse(c.content)
					c.content = newcontent
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
			puts "CORRECTED CATEGORIES for #{pID}"
		else
			#no reason why it should be nil.. store these oddballs here for now to do something with later. add p to the array of nilpages and create
			puts '??????? nil????????????????'
		end
		
	end

	
	
	
 

  





db.commit
if db.closed?()
	#do nothing
	else
	db.close
end
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
  xml_info.size("byte" => File.size("db-v3.db"), "num" => page_names.size)
}
fp_xml.close

File.copy(info_file, "/www/dl.android.wikem.org/files/info.xml")
puts "copied info file to ~~/files/info.xml"

#copy the db file to directory for dl by phone
File.copy("db-v3.db", "/www/dl.android.wikem.org/files/android_db")
puts "copied the db to ~~/files/android_db"
 
 