#!/usr/bin/env ruby


# ENV['RAILS_ENV'] ||= 'development'
# require File.dirname(__FILE__) + '/../config/environment'
require 'digest/md5'
require 'csv'
require 'ftools'
require 'mediawiki-gateway/lib/media_wiki'
require 'sqlite3'

curr_time = Time.now
RAILS_ROOT = File.dirname(__FILE__)

class Page
  attr_accessor :name, :folder, :content, :last_update, :author_name  
end

puts "try to scrape"
current_stamp = Time.now.to_i
mw = MediaWiki::Gateway.new('http://www.radswiki.net/api.php')
#page_names = mw.list('')
#

cats =[ "Category:Trachea", "Category:Trauma", "Category:Tuberculosis", "Category:US", "Category:US artifact", "Category:US books", "Category:US sample dictations", "Category:US signs in radiology", "Category:Umbilical cord", "Category:Ureter", "Category:Ureter neoplasm", "Category:Urethra", "Category:Uterus", "Category:VIR", "Category:VIR books", "Category:VIR image", "Category:VIR sample dictations", "Category:Vascular", "Category:Vascular medical device", "Category:Vasculitis", "Category:Venous", "Category:Volvulus", "Category:Wrist"]
#load the db
db = SQLite3::Database.new( "testrad.db")

zero = Integer('0')


##just do nested for loop
@pages = []
cats.each do |n|
  puts "Download pages for cat: #{n}"
  pageInCat=mw.list_pages_for_category(n)
	
   pageInCat.each do|z|
	puts "putting page: #{z} into db"	
	# page = Page.new
 	# page.name = z
	# page.folder = n
	# page.content = mw.render(z)
 	# page.last_update = current_stamp
 	# page.author_name = 'radswiki'
 	# @pages << page
db.execute("INSERT into FTSdictionary (suggest_text_1, DEFINITIONS, suggest_text_2, FAVORITE, LAST_UPDATE) VALUES (:name, :content, :category, :favorite, :lastupdate)", 
		"name" => z,
		"content" => mw.render(z),
		"category" => n,
		"favorite" => zero,
		"lastupdate" => current_stamp)
	end
end


