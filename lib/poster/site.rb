require 'uri'
require 'faraday'
require 'faraday-cookie_jar'
require 'nokogiri'

module Poster
  class Site
    include Poster::Encoding

    attr_accessor :url, :opts, :conn, :response, :page

    def initialize url:, **opts
      @url = URI.parse(url)
      @opts = opts
      @conn = connect @url
      login if @opts[:user] && @opts[:pass] && @opts[:login_path]
    end

    # Establish Faraday connection
    def connect uri
      Faraday.new(:url => "#{uri.scheme}://#{uri.host}") do |faraday|
        faraday.request :multipart
        faraday.request :url_encoded
        # faraday.use FaradayMiddleware::FollowRedirects, limit: 3
        faraday.use :cookie_jar
        faraday.response :logger                  # log requests to STDOUT
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
    end

    # Login to site
    def login
      post @opts[:login_path],
        body: {user: @opts[:user], passwrd: @opts[:pass]},
        content_type: 'application/x-www-form-urlencoded'
    end

    # Posting new topic
    def new_topic board: 92, subj: 'test', msg: 'msg', icon: "exclamation"
      # Check board posting page first (to get sequence numbers)
      get "/index.php?action=post;board=#{board}.0"

      raise "Not logged, cannot post!" unless logged?

      # Create new post
      seqnum, sc = find_fields 'seqnum', 'sc'
      subj = xml_encode(subj_encode(subj))
      msg = xml_encode(msg)
      post "/index.php?action=post2;start=0;board=#{board}",
        content_type: 'multipart/form-data; charset=ISO-8859-1',
        body: { topic: 0, subject: subj, icon: icon, message: msg,
                notify: 0, do_watch: 0,  selfmod: 0, lock: 0, goback: 1, ns: "NS", post: "Post",
                additional_options: 0, sc: sc, seqnum: seqnum },
        options: {timeout: 5}   # open/read timeout in seconds
      
      # Make sure the message was posted, return topic page
      new_topic = @response.headers['location']
      p @response.body
      raise "No redirect to posted topic!" unless new_topic && @response.status == 302
      get new_topic 
    end

    # Helpers
    def logged?
      @page && !@page.xpath("//span[@id='hellomember']").empty?
    end

    def find_fields *names
      names.map do |name|
        unless !@page || @page.xpath("//input[@name='#{name}']").empty?
          @page.xpath("//input[@name='#{name}']").first['value']
        end
      end
    end

    # Requesting
    def request url, method: :get, **opts
      @response = @conn.send(method, url) do |req|
        req.headers['Content-Type'] = opts[:content_type] if opts[:content_type]
        req.body = opts[:body] if opts[:body]
        opts[:options].each {|k,v| req.options.send("#{k}=", v)} if opts[:options]
        yield req if block_given?
      end
      p @response.status
      @page = Nokogiri::HTML(@response.body)
      @response
    end

    def get url, **opts, &block
      request url, method: :get, **opts, &block
    end

    def post url, **opts, &block
    	pp opts
      request url, method: :post, **opts, &block
    end

  end
end
