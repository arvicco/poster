require 'uri'
require 'faraday'
require 'faraday-cookie_jar'
require 'nokogiri'

module Poster
  # Site is a thin wrapper around Faraday::Connection
  class Site
    include Poster::Encoding

    attr_accessor :url, :opts, :conn, :response, :page

    def initialize url:, **opts
      @url = URI.parse(url)
      @opts = opts
      @conn = connect @url
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

    # Requesting
    def request url, method: :get, **opts
      @response = @conn.send(method, url) do |req|
        req.headers['Content-Type'] = opts[:content_type] if opts[:content_type]
        req.body = opts[:body] if opts[:body]
        opts[:options].each {|k,v| req.options.send("#{k}=", v)} if opts[:options]
        yield req if block_given?
      end
      puts "Status:#{@response.status}"
      @page = Nokogiri::HTML(@response.body)
      @response
    end

    def get url, **opts, &block
      request url, method: :get, **opts, &block
    end

    def post url, **opts, &block
      request url, method: :post, **opts, &block
    end

  end
end
