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
yesterday_time = Time.at(current_stamp - 1000)
arbitrarytime = yesterday_time.strftime("%Y%m%d%H%M%S")


class Page
  attr_accessor :name, :folder, :content, :last_update, :author_name  
end

 
 

mw = MediaWiki::Gateway.new('http://www.wikem.org/w/api.php')
mw.login('robot','wikem-vona')

#get 'newly created page' element of recent changes by using custom method in gateway.rb
edited_page_names = mw.list_recent_changes(arbitrarytime)
#get name of deleted pages

 
		
#reference arrays of edits, new pages, and lost pages (ie. edits to pages which for reasons unknown are not in our database) 
@editpages = []

#get edited page data for each unique page that was edited
if edited_page_names!=nil
edited_page_names.uniq!
	edited_page_names.each do |n|
	  #puts "Download page: #{n}"
	  page = Page.new
	  page.name = n
	  page.folder = mw.get_categories(n)
	  page.content = mw.render(n,{'linkbase' => ''} )
	  puts "#{page.content}"
	  page.last_update = current_stamp
	  page.author_name = 'WikEM'
	  @editpages << page
	end
end
 
