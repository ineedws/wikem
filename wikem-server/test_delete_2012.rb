require 'rubygems'
require 'sqlite3'

  db = SQLite::Database.new( "deletethistesetdb" )
db.cache_size=3000
 # db.execute( "select * from table" ) do |row|
   # p row
  
  db.close
