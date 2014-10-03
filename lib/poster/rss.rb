require 'poster/site'
require 'simple-rss'

module Poster
  # Represents an RSS resource
  class Rss < Site
    include Poster::Encoding
    attr_reader :feed

    def initialize url:, **opts
      super
      resp = get @url.path
      @feed = SimpleRSS.parse resp.body
    end

    # Extract news data from a feed item
    def extract_data item, text_limit: 1200
      link = item.link
      desc = item.description
      title = item.title.force_encoding('UTF-8')
      
      # Extract main image
      case
      when desc.include?('|')
        img, text = desc.split('|')
      when desc.match(/&lt;img.*?src="(.*?)\"/)
        img = desc.match(/&lt;img.*?src="(.*?)\"/)[1]
        text = desc
      else
        img, text = nil, desc
      end

      # Crop text
      short_text = strip_tags(text)[0..text_limit]
      
      # Normalize newlines
      short_text = short_text.gsub(/\n+/,"\n\n")
      
      # Right-strip to end of last paragraph
      short_text = short_text[0..short_text.rindex(/\.\n/)]

      [title, link, img, short_text]
    end
  end
end
