require 'rubygems'
require 'logger'
require 'rest_client'
require 'rexml/document'
require 'uri'

module MediaWiki
  
  class Gateway
    attr_reader :log
    
    # Set up a MediaWiki::Gateway for a given MediaWiki installation
    #
    # [url] Path to API of target MediaWiki (eg. "http://en.wikipedia.org/w/api.php")
    # [options] Hash of options
    #
    # Options:
    # [:ignorewarnings] Log API warnings and invalid page titles, instead of aborting with an error.
    # [:limit] Maximum number of results returned per search (see http://www.mediawiki.org/wiki/API:Query_-_Lists#Limits), defaults to the MediaWiki default of 500.
    # [:loglevel] Log level to use, defaults to Logger::WARN.  Set to Logger::DEBUG to dump every request and response to the log.
    # [:maxlag] Maximum allowed server lag (see http://www.mediawiki.org/wiki/Manual:Maxlag_parameter), defaults to 5 seconds.
    # [:retry_count] Number of times to try before giving up if MediaWiki returns 503 Service Unavailable, defaults to 3 (original request plus two retries).
    # [:retry_delay] Seconds to wait before retry if MediaWiki returns 503 Service Unavailable, defaults to 10 seconds.
    def initialize(url, options={})
      default_options = {
        :limit => 5000,
        :loglevel => Logger::WARN,
        :maxlag => 5,
        :retry_count => 3,
        :retry_delay => 10
      }
      @options = default_options.merge(options)
      @wiki_url = url
      @log = Logger.new(STDERR)
      @log.level = @options[:loglevel]
      @headers = { "User-Agent" => "MediaWiki::Gateway/#{MediaWiki::VERSION}" }
      @cookies = {}
    end
    
    attr_reader :base_url
    
    # Login to MediaWiki
    #
    # [username] Username
    # [password] Password
    # [domain] Domain for authentication plugin logins (eg. LDAP), optional -- defaults to 'local' if not given
    #
    # Throws error if login fails
    def login(username, password, domain = 'local')
      form_data = {'action' => 'login', 'lgname' => username, 'lgpassword' => password, 'lgdomain' => domain}
      make_api_request(form_data)
      @password = password
      @username = username
    end
    
    # Fetch MediaWiki page in MediaWiki format.  Does not follow redirects.
    #
    # [page_title] Page title to fetch
    #
    # Returns content of page as string, nil if the page does not exist.
    def get(page_title)
      form_data = {'action' => 'query', 'prop' => 'revisions', 'rvprop' => 'content', 'titles' => page_title}
      page = make_api_request(form_data).first.elements["query/pages/page"]
      if valid_page? page
        page.elements["revisions/rev"].text || ""
      end
    end
    
    # Get MediaWiki Page Categories
    #
    # [page_title] Page title to fetch
    #
    # Returns list of categories, nil if none exist
    def get_categories(page_title)
      form_data = {'action' => 'query', 'prop' => 'categories|info', 'titles' => page_title}
      cats = [];
      api_data = make_api_request(form_data)
      categories = api_data.first.elements["query/pages/page/categories"]
      # last_update = api_data.first.elements["query/pages/page"]
      if categories
        categories.elements.each("cl") do |c|
          cats << c.attributes["title"].sub('Category:','')
        end
      end
      
      return cats
    end
	
	
	##ck: Get the page name from the id
	def get_name(pageid)
	form_data =
          {'action' => 'query',
          'prop' => 'info',
          'pageids' => pageid}
		api_data = make_api_request(form_data).first.elements["query/pages/page"]
		title = api_data.attributes["title"] 
		return title
	end	
	
	
	
###ck: Get the last update given a page title
	def get_last_update(page_title)
	 #todo
	end
	
	
    # Render a MediaWiki page as HTML
    #
    # [page_title] Page title to fetch
    # [options] Hash of additional options
    #
    # Options:
    # * [:linkbase] supply a String to prefix all internal (relative) links with. '/wiki/' is assumed to be the base of a relative link
    # * [:noeditsections] strips all edit-links if set to +true+
    # * [:noimages] strips all +img+ tags from the rendered text if set to +true+
    # 
    # Returns rendered page as string, or nil if the page does not exist
    def render(page_title, options = {})
      form_data = {'action' => 'parse', 'page' => page_title}

      valid_options = %w(linkbase noeditsections noimages)
      # Check options
      options.keys.each{|opt| raise ArgumentError.new("Unknown option '#{opt}'") unless valid_options.include?(opt.to_s)}

      rendered = nil
      parsed = make_api_request(form_data).first.elements["parse"]
      if parsed.attributes["revid"] != '0'
        rendered = parsed.elements["text"].text.gsub(/<!--(.|\s)*?-->/, '')
        # OPTIMIZE: unifiy the keys in +options+ like symbolize_keys! but w/o
        if options["linkbase"] or options[:linkbase]
          linkbase = options["linkbase"] || options[:linkbase]
          rendered = rendered.gsub(/\shref="\/wiki\/([\w\(\)_\-\.%\d:,]*)"/, ' href="' + linkbase + '/wiki/\1"')
		

        end
        if options["noeditsections"] or options[:noeditsections]
          rendered = rendered.gsub(/<span class="editsection">\[.+\]<\/span>/, '')
        end
        if options["noimages"] or options[:noimages]
          rendered = rendered.gsub(/<img.*\/>/, '')
        end
      end
      rendered
    end
        
    # Create a new page, or overwrite an existing one
    #
    # [title] Page title to create or overwrite, string
    # [content] Content for the page, string
    # [options] Hash of additional options
    #
    # Options:
    # * [:overwrite] Allow overwriting existing pages
    # * [:summary] Edit summary for history, string
    # * [:token] Use this existing edit token instead requesting a new one (useful for bulk loads)
    def create(title, content, options={})
      form_data = {'action' => 'edit', 'title' => title, 'text' => content, 'summary' => (options[:summary] || ""), 'token' => get_token('edit', title)}
      form_data['createonly'] = "" unless options[:overwrite]
      make_api_request(form_data)
    end

    # Edit page
    #
    # Same options as create, but always overwrites existing pages (and creates them if they don't exist already).
    def edit(title, content, options={})
      create(title, content, {:overwrite => true}.merge(options))
    end

    # Move a page to a new title
    #
    # [from] Old page name
    # [to] New page name
    # [options] Hash of additional options
    #
    # Options:
    # * [:movesubpages] Move associated subpages
    # * [:movetalk] Move associated talkpages
    # * [:noredirect] Do not create a redirect page from old name.  Requires the 'suppressredirect' user right, otherwise MW will silently ignore the option and create the redirect anyway.
    # * [:reason] Reason for move
    # * [:watch] Add page and any redirect to watchlist
    # * [:unwatch] Remove page and any redirect from watchlist
    def move(from, to, options={})
      valid_options = %w(movesubpages movetalk noredirect reason watch unwatch)
      options.keys.each{|opt| raise ArgumentError.new("Unknown option '#{opt}'") unless valid_options.include?(opt.to_s)}
      
      form_data = options.merge({'action' => 'move', 'from' => from, 'to' => to, 'token' => get_token('move', from)})
      make_api_request(form_data)
    end
    
    # Delete one page. (MediaWiki API does not support deleting multiple pages at a time.)
    #
    # [title] Title of page to delete
    def delete(title)
      form_data = {'action' => 'delete', 'title' => title, 'token' => get_token('delete', title)}
      make_api_request(form_data)
    end

    # Undelete all revisions of one page.
    #
    # [title] Title of page to undelete
    #
    # Returns number of revisions undeleted, or zero if nothing to undelete
    def undelete(title)
      token = get_undelete_token(title)
      if token
        form_data = {'action' => 'undelete', 'title' => title, 'token' => token }
        make_api_request(form_data).first.elements["undelete"].attributes["revisions"].to_i
      else
        0 # No revisions to undelete
      end
    end

    # Get a list of matching page titles in a namespace
    #
    # [key] Search key, matched as a prefix (^key.*).  May contain or equal a namespace, defaults to main (namespace 0) if none given.
    #
    # Returns array of page titles (empty if no matches)
    def list(key)
      titles = []
      apfrom = nil
      key, namespace = key.split(":", 2).reverse
      namespace = namespaces_by_prefix[namespace] || 0
      begin
        form_data =
          {'action' => 'query',
          'list' => 'allpages',
          'apfrom' => apfrom,
          'apprefix' => key,
          'aplimit' => @options[:limit],
          'apnamespace' => namespace}
        res, apfrom = make_api_request(form_data, '//query-continue/allpages/@apfrom')
        titles += REXML::XPath.match(res, "//p").map { |x| x.attributes["title"] }
      end while apfrom
      titles
    end
	
	  # Returns array of page titles of redirects only (empty if no matches)
    def list_redirects(key)
      titles = []
      apfrom = nil
      key, namespace = key.split(":", 2).reverse
      namespace = namespaces_by_prefix[namespace] || 0
      begin
        form_data =
          {'action' => 'query',
          'list' => 'allpages',
          'apfrom' => apfrom,
          'apprefix' => key,
          'aplimit' => @options[:limit],
          'apnamespace' => namespace,
		  'apfilterredir' => 'redirects'}
        res, apfrom = make_api_request(form_data, '//query-continue/allpages/@apfrom')
        titles += REXML::XPath.match(res, "//p").map { |x| x.attributes["title"] }
      end while apfrom
      titles
    end
	
	# returns array of redirect pages with their targets
	# http://wikem.org/w/api.php?action=query&list=querypage&qppage=Listredirects&qplimit=5000
	def list_redirects_with_targets
		redirects = []
		apfrom = nil
		begin
			form_data =
			{'action' => 'query',
			'list' => 'querypage',
			'qppage' => 'Listredirects',          
			'qplimit' => @options[:limit]}
			res, apfrom = make_api_request(form_data, '//query-continue/querypage/@apfrom')
			redirects += REXML::XPath.match(res)
		end while apfrom
						
		unless redirects.nil? || redirects == ''
			# create hash for pairs redirect => target (old url => new url)
			redirect_with_targets = {}
			REXML::XPath.match(redirects, '//page').each do |item|
				redirect = item.attributes['value']
				target = item.elements['databaseResult'].attributes['rd_title']
				redirect_with_targets[redirect] = target
			end
			redirect_with_targets
		end
	end
	
	  # Returns multi dimensional array of all users, default width of 4
#for the 4 fields: name, realname, custom1, custom2 	  
	  
    def list_all_users()
	
	titles = []
	 apfrom = nil
      begin
        form_data =
          {'action' => 'query',
          'list' => 'allusers',
          'aulimit' => @options[:limit],         
		  }
        res, apfrom = make_api_request(form_data, '//query-continue/allpages/@apfrom')
#		temp = []
 #       temp+= REXML::XPath.match(res, "//u").map { |x| x.attributes["name"] }
	#	temp+= REXML::XPath.match(res, "//u").map { |x| x.attributes["realname"] }
	#	temp+= REXML::XPath.match(res, "//u").map { |x| x.attributes["custom1"] }
	#	temp+= REXML::XPath.match(res, "//u").map { |x| x.attributes["custom2"] }
	#	titles+=temp
#parent.each_child{ |child| # Do something with child }	
		
		 REXML::XPath.match(res, "//u").each do |x|
				temp = Array.new
			   temp[0]= x.attributes["name"]
			   temp[1]= x.attributes["realname"] 
			   temp[2] = x.attributes["custom1"]
			   temp[3] = x.attributes["custom2"]
			   titles += temp
			  end

      end  while apfrom
      return titles
    end
	
###ck: list all pages for category.
def list_pages_for_category(cat)
	titles = []
      
      begin
        form_data =
          {'action' => 'query',
          'list' => 'categorymembers',
          'cmtitle' => cat,
          'cmlimit' => 500,
		   }
        res, apfrom = make_api_request(form_data, '//query-continue/allpages/@apfrom')
        titles += REXML::XPath.match(res, "//cm").map { |x| x.attributes["title"] }
      end while apfrom
      titles
end
	
###ck: TODO return images after adding hook upon new file upload
def list_images(timestamp)
		images = []
		
	begin
		    form_data =
          {'action' => 'query',
           'prop' => 'images',
          'list' => 'allimages',
          'ailimit' => 4999
          }
        res, apfrom = make_api_request(form_data, '//query-continue/allpages/@apfrom')
       images += REXML::XPath.match(res, "//img").map { |x| x.attributes["url"] }
      end while apfrom
	  images
	end


### ck: list recent (updated or new) pages,  	
 # Returns array of page titles (empty if no matches)
 #increase  rclimit later... for bots up to 5000
 #ruby xml processor -> xpath.match Returns an array of nodes matching a given XPath.


    def list_recent_changes(timestamp)
      titles = []
      
      begin
        form_data =
          {'action' => 'query',
          'list' => 'recentchanges',
          'rcend' => timestamp,
          'rclimit' => 500,
		  'rcshow' => '!redirect',
		  'rcnamespace' => 0,
		  'rctype' => 'edit'
          }
        res, apfrom = make_api_request(form_data, '//query-continue/allpages/@apfrom')
        titles += REXML::XPath.match(res, "//rc").map { |x| x.attributes["title"] }
      end while apfrom
      titles
    end
###ck:same as list_recent_changes (which gets edits) except gets only NEW	
 def list_new(timestamp)
      titles = []
      
      begin
        form_data =
          {'action' => 'query',
          'list' => 'recentchanges',
          'rcend' => timestamp,
          'rclimit' => 500,
		  'rcshow' => '!redirect',
		  'rcnamespace' => 0,
		  'rctype' => 'new'
          }
        res, apfrom = make_api_request(form_data, '//query-continue/allpages/@apfrom')
        titles += REXML::XPath.match(res, "//rc").map { |x| x.attributes["title"] }
      end while apfrom
      titles
    end
	
	
### ck: gives the pageid based off of pagetitles that start with the key
	def list_pageid(key)
      titles = []
      apfrom = nil
      key, namespace = key.split(":", 2).reverse
      namespace = namespaces_by_prefix[namespace] || 0
      begin
        form_data =
          {'action' => 'query',
          'list' => 'allpages',
          'apfrom' => apfrom,
          'apprefix' => key,
          'aplimit' => @options[:limit],
          'apnamespace' => namespace,
		  'apfilterredir' => 'nonredirects'}
        res, apfrom = make_api_request(form_data, '//query-continue/allpages/@apfrom')
        titles += REXML::XPath.match(res, "//p").map { |x| x.attributes["pageid"] }
      end while apfrom
      titles
    end
	
	###ck:gets a title list of deletions based off timestamp using the 'logevents' log	
 def list_deleted(timestamp)
      titles = []
      
      begin
        form_data =
          {'action' => 'query',
          'list' => 'logevents',
          'letype' => 'delete',
          'leprop' => 'title',
		  'leend' => timestamp,
		  'lelimit' => '400'
		 
          }
        res, apfrom = make_api_request(form_data, '//query-continue/allpages/@apfrom')
        titles += REXML::XPath.match(res, "//item").map { |x| x.attributes["title"] }
      end while apfrom
      titles
    end
	
	
	
	#returns array of moved, old titles only
	def list_moved_oldtitles(timestamp)
      titles = []
	  
	  #throws error bc default for list page is only 10 so explicit change the limit
      begin
        form_data =
          {'action' => 'query',
          'list' => 'logevents',
          'letype' => 'move',
          'leprop' => 'title',
		  'leend' => timestamp,
			'lelimit' => '400'		  
          }
        res, apfrom = make_api_request(form_data, '//query-continue/allpages/@apfrom')
        titles += REXML::XPath.match(res, "//item").map { |x| x.attributes["title"] }        
      end while apfrom
	  titles
    end
	
	
	
	#get moved list array...only new titles
	def list_moved_newtitles(timestamp)
      titles = []
	  
      begin
        form_data =
          {'action' => 'query',
          'list' => 'logevents',
          'letype' => 'move',
          'leprop' => 'details',
		  'leend' => timestamp,
		'lelimit' => '400'		  
          }
        res, apfrom = make_api_request(form_data, '//query-continue/allpages/@apfrom')
        titles += REXML::XPath.match(res, "//item/move").map { |x| x.attributes["new_title"] }
      end while apfrom
	  titles
    end
	#ck TODO list restore... restoring may throw up error.. in future..
	
	

    # Get a list of pages that link to a target page
    #
    # [title] Link target page
    # [filter] "all" links (default), "redirects" only, or "nonredirects" (plain links only)
    #
    # Returns array of page titles (empty if no matches)
    def backlinks(title, filter = "all")
      titles = []
      blcontinue = nil
      begin
        form_data =
          {'action' => 'query',
          'list' => 'backlinks',
          'bltitle' => title,
          'blfilterredir' => filter,
          'bllimit' => @options[:limit] }
        form_data['blcontinue'] = blcontinue if blcontinue
        res, blcontinue = make_api_request(form_data, '//query-continue/backlinks/@blcontinue')
        titles += REXML::XPath.match(res, "//bl").map { |x| x.attributes["title"] }
      end while blcontinue
      titles
    end

    # Get a list of pages with matching content in given namespaces
    #
    # [key] Search key
    # [namespaces] Array of namespace names to search (defaults to main only)
    # [limit] Maximum number of hits to ask for (defaults to 500; note that Wikimedia Foundation wikis allow only 50 for normal users)
    #
    # Returns array of page titles (empty if no matches)
    def search(key, namespaces=nil, limit=@options[:limit])
      titles = []
      offset = nil
      in_progress = true

      form_data = { 'action' => 'query',
        'list' => 'search',
        'srwhat' => 'text',
        'srsearch' => key,
        'srlimit' => limit
      }
      if namespaces
        namespaces = [ namespaces ] unless namespaces.kind_of? Array
        form_data['srnamespace'] = namespaces.map! do |ns| namespaces_by_prefix[ns] end.join('|')
      end
      begin
        form_data['sroffset'] = offset if offset
        res, offset = make_api_request(form_data, '//query-continue/search/@sroffset')
        titles += REXML::XPath.match(res, "//p").map { |x| x.attributes["title"] }
      end while offset
      titles
    end

    # Upload a file, or get the status of pending uploads. Several 
    # methods are available:
    #
    # * Upload file contents directly.
    # * Have the MediaWiki server fetch a file from a URL, using the 
    #   "url" parameter
    #
    # Requires Mediawiki 1.16+
    #
    # Arguments:
    # * [path] Path to file to upload. Set to nil if uploading from URL.
    # * [options] Hash of additional options
    # 
    # Note that queries using session keys must be done in the same login 
    # session as the query that originally returned the key (i.e. do not
    # log out and then log back in).
    #
    # Options:
    # * 'filename'       - Target filename (defaults to local name if not given), options[:target] is alias for this.
    # * 'comment'        - Upload comment. Also used as the initial page text for new files if "text" is not specified.
    # * 'text'           - Initial page text for new files
    # * 'watch'          - Watch the page
    # * 'ignorewarnings' - Ignore any warnings
    # * 'url'            - Url to fetch the file from. Set path to nil if you want to use this.
    #
    # Deprecated but still supported options:
    # * :description     - Description of this file. Used as 'text'.
    # * :target          - Target filename, same as 'filename'.
    # * :summary         - Edit summary for history. Used as 'comment'. Also used as 'text' if neither it or :description is specified.
    # 
    # Examples:
    #   mw.upload('/path/to/local/file.jpg', 'filename' => "RemoteFile.jpg")
    #   mw.upload(nil, 'filename' => "RemoteFile2.jpg", 'url' => 'http://remote.com/server/file.jpg')
    #
    def upload(path, options={})
      if options[:description]
        options['text'] = options[:description]
        options.delete(:description)
      end

      if options[:target]
        options['filename'] = options[:target]
        options.delete(:target)
      end

      if options[:summary]
        options['text'] ||= options[:summary]
        options['comment'] = options[:summary]
        options.delete(:summary)
      end

      options['comment'] ||= "Uploaded by MediaWiki::Gateway"
      options['file'] = File.new(path) if path
      full_name = path || options['url']
      options['filename'] ||= File.basename(full_name) if full_name

      raise ArgumentError.new(
        "One of the 'file', 'url' or 'sessionkey' options must be specified!"
      ) unless options['file'] || options['url'] || options['sessionkey']

      form_data = options.merge(
        'action' => 'upload',
        'token' => get_token('edit', options['filename'])
      )

      make_api_request(form_data)
    end

    # Checks if page is a redirect.
    #
    # [page_title] Page title to fetch
    #
    # Returns true if the page is a redirect, false if it is not or the page does not exist.
    def redirect?(page_title)
      form_data = {'action' => 'query', 'prop' => 'info', 'titles' => page_title}
      page = make_api_request(form_data).first.elements["query/pages/page"]
      !!(valid_page?(page) and page.attributes["redirect"])
    end
    
    # Requests image info from MediaWiki. Follows redirects.
    #
    # _file_name_or_page_id_ should be either:
    # * a file name (String) you want info about without File: prefix.
    # * or a Fixnum page id you of the file.
    #
    # _options_ is +Hash+ passed as query arguments. See
    # http://www.mediawiki.org/wiki/API:Query_-_Properties#imageinfo_.2F_ii
    # for more information.
    #
    # options['iiprop'] should be either a string of properties joined by
    # '|' or an +Array+ (or more precisely something that responds to #join).
    #
    # +Hash+ like object is returned where keys are image properties.
    #
    # Example:
    #   mw.image_info(
    #     "Trooper.jpg", 'iiprop' => ['timestamp', 'user']
    #   ).each do |key, value|
    #     puts "#{key.inspect} => #{value.inspect}"
    #   end
    #
    # Output:
    #   "timestamp" => "2009-10-31T12:59:11Z"
    #   "user" => "Valdas"
    #
    def image_info(file_name_or_page_id, options={})
      options['iiprop'] = options['iiprop'].join('|') \
        if options['iiprop'].respond_to?(:join)
      form_data = options.merge(
        'action' => 'query',
        'prop' => 'imageinfo',
        'redirects' => true
      )

      case file_name_or_page_id
      when Fixnum
        form_data['pageids'] = file_name_or_page_id
      else
        form_data['titles'] = "File:#{file_name_or_page_id}"
      end

      xml, dummy = make_api_request(form_data)
      page = xml.elements["query/pages/page"]
      if valid_page? page
        if xml.elements["query/redirects/r"]
          # We're dealing with redirect here.
          image_info(page.attributes["pageid"].to_i, options)
        else
          page.elements["imageinfo/ii"].attributes
        end
      else
        nil
      end
    end

    # Download _file_name_. Returns file contents. All options are passed to 
    # #image_info however options['iiprop'] is forced to url. You can still
    # set other options to control what file you want to download.
    def download(file_name, options={})
      options['iiprop'] = 'url'
  
      attributes = image_info(file_name, options)
      if attributes
        RestClient.get attributes['url']
      else
        nil
      end
    end

    # Imports a MediaWiki XML dump
    #
    # [xml] String or array of page names to fetch
    #
    # Returns XML array <api><import><page/><page/>... 
    # <page revisions="1"> (or more) means successfully imported
    # <page revisions="0"> means duplicate, not imported
    def import(xmlfile)
      form_data = { "action"  => "import",
        "xml"     => File.new(xmlfile),
        "token"   => get_token('import', 'Main Page'), # NB: dummy page name
        "format"  => 'xml' }
      make_api_request(form_data)
    end

    # Exports a page or set of pages
    #
    # [page_titles] String or array of page titles to fetch
    #
    # Returns MediaWiki XML dump
    def export(page_titles)
      form_data = {'action' => 'query', 'titles' => [page_titles].join('|'), 'export' => nil, 'exportnowrap' => nil}
      return make_api_request(form_data)
    end

    # Get a list of all known namespaces
    #
    # Returns array of namespaces (name => id)
    def namespaces_by_prefix
      form_data = { 'action' => 'query', 'meta' => 'siteinfo', 'siprop' => 'namespaces' }
      res = make_api_request(form_data)
      REXML::XPath.match(res, "//ns").inject(Hash.new) do |namespaces, namespace|
        prefix = namespace.attributes["canonical"] || ""
        namespaces[prefix] = namespace.attributes["id"].to_i
        namespaces
      end
    end

    # Get a list of all installed (and registered) extensions
    #
    # Returns array of extensions (name => version)
    def extensions
      form_data = { 'action' => 'query', 'meta' => 'siteinfo', 'siprop' => 'extensions' }
      res = make_api_request(form_data)
      REXML::XPath.match(res, "//ext").inject(Hash.new) do |extensions, extension|
        name = extension.attributes["name"] || ""
        extensions[name] = extension.attributes["version"]
        extensions
      end
    end
    
    # Execute Semantic Mediawiki query
    #
    # [query] Semantic Mediawiki query
    # [params] Array of additional parameters or options, eg. mainlabel=Foo or ?Place (optional)
    #
    # Returns result as an HTML string
    def semantic_query(query, params = [])
      params << "format=list"
      form_data = { 'action' => 'parse', 'prop' => 'text', 'text' => "{{#ask:#{query}|#{params.join('|')}}}" }
      xml, dummy = make_api_request(form_data)
      return xml.elements["parse/text"].text
    end

    private

    # Fetch token (type 'delete', 'edit', 'import', 'move')
    def get_token(type, page_titles)
      form_data = {'action' => 'query', 'prop' => 'info', 'intoken' => type, 'titles' => page_titles}
      res, dummy = make_api_request(form_data)
      token = res.elements["query/pages/page"].attributes[type + "token"]
      raise "User is not permitted to perform this operation: #{type}" if token.nil?
      token
    end

    def get_undelete_token(page_titles)
      form_data = {'action' => 'query', 'list' => 'deletedrevs', 'prop' => 'info', 'drprop' => 'token', 'titles' => page_titles}
      res, dummy = make_api_request(form_data)
      if res.elements["query/deletedrevs/page"]
        token = res.elements["query/deletedrevs/page"].attributes["token"]
        raise "User is not permitted to perform this operation: #{type}" if token.nil?
        token
      else
        nil
      end
    end

    # Make generic request to API
    #
    # [form_data] hash or string of attributes to post
    # [continue_xpath] XPath selector for query continue parameter
    # [retry_count] Counter for retries
    #
    # Returns XML document
    def make_api_request(form_data, continue_xpath=nil, retry_count=1)
      if form_data.kind_of? Hash
        form_data['format'] = 'xml'
        form_data['maxlag'] = @options[:maxlag]
      end
      log.debug("REQ: #{form_data.inspect}, #{@cookies.inspect}")
      RestClient.post(@wiki_url, form_data, @headers.merge({:cookies => @cookies})) do |response, &block|
        if response.code == 503 and retry_count < @options[:retry_count]
          log.warn("503 Service Unavailable: #{response.body}.  Retry in #{@options[:retry_delay]} seconds.")
          sleep @options[:retry_delay]
          make_api_request(form_data, continue_xpath, retry_count + 1)
        end
        # Check response for errors and return XML
        raise "API error, bad response: #{response}" unless response.code >= 200 and response.code < 300 
        doc = get_response(response.dup)
        if(form_data['action'] == 'login')
          login_result = doc.elements["login"].attributes['result']
          @cookies.merge!(response.cookies)
          case login_result
            when "Success" then # do nothing
            when "NeedToken" then make_api_request(form_data.merge('lgtoken' => doc.elements["login"].attributes["token"]))
            else raise "Login failed: " + login_result
          end
        end
        continue = (continue_xpath and doc.elements['query-continue']) ? REXML::XPath.first(doc, continue_xpath) : nil
        return [doc, continue]
      end
    end
    
    # Get API XML response
    # If there are errors or warnings, raise exception
    # Otherwise return XML root
    def get_response(res)
      begin
        doc = REXML::Document.new(res).root
      rescue REXML::ParseException => e
        raise "Response is not XML.  Are you sure you are pointing to api.php?"
      end
      log.debug("RES: #{doc}")
      raise "Response does not contain Mediawiki API XML: #{res}" unless [ "api", "mediawiki" ].include? doc.name
      if doc.elements["error"]
        code = doc.elements["error"].attributes["code"]
        info = doc.elements["error"].attributes["info"]
        raise "API error: code '#{code}', info '#{info}'"
      end
      if doc.elements["warnings"]
        warning("API warning: #{doc.elements["warnings"].children.map {|e| e.text}.join(", ")}")
      end
      doc
    end
    
    def valid_page?(page)
      return false unless page
      return false if page.attributes["missing"]
      if page.attributes["invalid"]
        warning("Invalid title '#{page.attributes["title"]}'")
      else
        true
      end
    end
    
    def warning(msg)
      if @options[:ignorewarnings]
        log.warn(msg)
        return false
      else
        raise msg
      end
    end
  end
end
