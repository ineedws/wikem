#!/usr/bin/env ruby


# ENV['RAILS_ENV'] ||= 'development'
# require File.dirname(__FILE__) + '/../config/environment'
require 'digest/md5'
require 'csv'
require 'ftools'
require 'mediawiki-gateway/lib/media_wiki'


RAILS_ROOT = File.dirname(__FILE__)

#####################
#### this script is like the AndroidSQLGeneratorv2, 
#### except instead of running in crontab every minute, 
#### MANUALLY call script to rebuild updates to some arbitrary time.
#### like other scripts, in this directory contains the two source files
#### copy-of-lastmadedb.xml and db.db
#####################

  


class Page
  attr_accessor :name, :folder, :content, :last_update, :author_name  
end

 
require 'rubygems'
require 'builder'
require 'nokogiri'
curr_time = Time.now

#opening the nokogiri xml doc
#buffer = File.open("/www/dl.android.wikem.org/db-update.xml",'r').read
buffer = File.open("copy-of-lastmadedb.xml",'r').read
doc = Nokogiri::XML(buffer)
 
 require 'cgi'

makechange = false 

booldebug = true
 doc.xpath('//pages/page').each do |p|
 #puts ("page is #{p}")
	p.children.each do |child|		
		if(child.name == "content")
			
			contentnode = doc.at_css("content")
			#the inner html is all escaped. maybe have to use CGI unescape...
			#temp = contentnode.inner_html()
			temp = contentnode.content()
			unescaped = CGI.unescape(temp)
		#	contenttohtml=contentnode.to_html()
			#just display the first content to check..
				if(booldebug==true)
			#	puts("#{temp}")
				booldebug = false
				end
			
			
			#temphtml = contentnode.to_html()
		#	tempdoc = Nokogiri::HTML(contenttohtml)
			tempdoc = Nokogiri::XML(unescaped)
			tempdoc.xpath('//img').each do |alink|
		#		puts "asafdsafd"
		#	tempdoc.css('a').each do |alink|
			#	src = img.attributes["src"].value 
			#	puts "full src of img tag is #{src}"
			#	filename = File.basename(src)
			#	puts "file name is #{filename}"
			#	img.attributes["src"].value = filename	
			#	makechange = true
			   	###
			#	href = img.attributes["href"].value
			#	puts"href #{href}"
			#	puts "#{alink.content()}"
			acontent = alink.inner_text()
			if (	acontent.include? 'img' )
			puts "#{acontent}"
			end
				linkchild = alink.child()
					if(linkchild != nil)
					if(linkchild.name()== 'img')
						if( linkchild.attributes["src"])
							src = linkchild.attributes["src"].value
						
                               				 puts "full src of img tag is #{src}"
                               				 filename = File.basename(src)
                               				 puts "file name is #{filename}"
                               				 linkchild.attributes["src"].value = filename
                                			makechange = true
						end
					end
					end
				end
				
			if(makechange == true)
				puts "commit the change"
				#c.content = tempdoc.to_s
				#contentnode.inner_html=tempdoc
				#child.content = new	

					#use node class inner_html=(node_or_tags)
				contentnode.inner_html = tempdoc
				#reset bool
				makechange = false
			end
		end
	end
 end
#write these XML changes to file.
puts "writing to ~~/files/db-test.xml"
File.open('/www/dl.android.wikem.org/files/db-test.xml','w') {|f| doc.write_xml_to f}
#keep the copy for the script to open next time
  

# write info for the new info file, for android number of files no longer matters
#for iphone?
info_file = File.dirname(__FILE__) + "/public/info.xml"
fp_xml = File.open(info_file, 'w')
xml_info = Builder::XmlMarkup.new(:target => fp_xml)
xml_info.instruct!
xml_info.root {
  xml_info.lastupdate("epoch" => curr_time.to_i)
  xml_info.size("byte" => File.size("db.db"), "num" => "1")
}
fp_xml.close

File.copy(info_file, "/www/dl.android.wikem.org/files/info-test.xml")
puts "copied info file to ~~/files/info-test.xml"
 
 
