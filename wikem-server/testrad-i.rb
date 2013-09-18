#!/usr/bin/env ruby


# ENV['RAILS_ENV'] ||= 'development'
# require File.dirname(__FILE__) + '/../config/environment'


f = "www.radswiki.net/main/index.php?title=File:Central_Pontine_Myelinolysis_001.jpg"
t = "testrad.image"
"puts try to dl"

  def download full_url, to_here
      require 'open-uri'
      writeOut = open(to_here, "wb")
      writeOut.write(open(full_url).read)
      writeOut.close
    end

download(t,f)
puts "done downloading"
