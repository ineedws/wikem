#!/usr/bin/env ruby


# ENV['RAILS_ENV'] ||= 'development'
# require File.dirname(__FILE__) + '/../config/environment'
require 'digest/md5'
require 'csv'
require 'ftools'
require 'mediawiki-gateway/lib/media_wiki'


RAILS_ROOT = File.dirname(__FILE__)

#####################
###testing out link strips based off editpages on arbitrary time
#changed only one line of mediawikigateway render method.
#####################

current_stamp = Time.now.to_i
yesterday_time = Time.at(current_stamp - 86400)
arbitrarytime = yesterday_time.strftime("%Y%m%d%H%M%S")


class Page
  attr_accessor :name, :folder, :content, :last_update, :author_name  
end

 
 

mw = MediaWiki::Gateway.new('http://www.wikem.org/w/api.php')
mw.login('robot','wikem-vona')
 
#get all page edits minus 'redirects' 
edited_page_names = mw.list_recent_changes(arbitrarytime)
 
 	
#reference arrays of edits, new pages, and lost pages (ie. edits to pages which for reasons unknown are not in our database) 
@editpages = []
@newpages = []
@nilpages = []

require 'rubygems'
require 'nokogiri'
class String
#only bc doc.to_s  creates a full html and printes out doctype on line 1
  def remove_first_line!
    first_newline = (index("\n") || size - 1) + 1
    slice!(0, first_newline).sub("\n",'')
  end
end

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
		#page.content = doc.to_s
		#puts "after link change: #{content}"	
		linkchanged = true
	end
	if(linkchanged == true)
		temp = doc.to_s
		temp.remove_first_line!
		puts "now string is #{temp}"
		return temp
	else
		return content
	end
end
 
#get edited page data for each unique page that was edited
#eg.<a href="/wiki/File:ToothNumbering.jpg" class="image">
#<img alt="ToothNumbering.jpg" src="/w/images/a/ac/ToothNumbering.jpg" width="600" height="448" /></a> 
if edited_page_names!=nil
edited_page_names.uniq!
	edited_page_names.each do |n|
	  #puts "Download page: #{n}"
	  page = Page.new
	  page.name = n
	  page.folder = mw.get_categories(n)
	 # page.content = mw.render(n)
	  rendered = mw.render(n)
	  page.content = image_linkparse(rendered)
	  #puts "#{page.content}"
	  page.last_update = current_stamp
	  page.author_name = 'WikEM'
	  @editpages << page
	end

#for each page, must strip image links for compatability with mobile device. 
 

end
 
 