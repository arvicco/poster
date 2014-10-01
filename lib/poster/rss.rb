require 'poster/site'
require 'simple-rss'

module Poster
  # Represents an RSS resource 
  class Rss < Site
    attr_reader :feed
    
    def initialize url:, **opts
      super
      resp = get @url.path
      @feed = SimpleRSS.parse resp.body
    end
  end
end
