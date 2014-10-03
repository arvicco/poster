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
      when desc.match(/\|.*\|/m)
        img, terms, text = desc.split('|')
      when desc.include?('|')
        img, text = desc.split('|')
        terms = nil
      when desc.match(/&lt;img.*?src="(.*?)\"/)
        img = desc.match(/&lt;img.*?src="(.*?)\"/)[1]
        text = desc
        terms = nil
      else
        img, terms, text = nil, nil, desc
      end

      # Extract categories
      categories =
      if terms
        terms.split(/term_group: .*\n/).
          select {|g| g.match /taxonomy: category/}.
          map {|c| c.match( /name: (.*)\n/)[1]}
      else
        []
      end

      # Crop text
      short_text = strip_tags(text)[0..text_limit]

      # Normalize newlines
      short_text = short_text.gsub(/\A\s+/,"").gsub(/\n+/,"\n\n")

      # Right-strip to end of last paragraph
      short_text = short_text[0..short_text.rindex(/\.\n/)]

      [title, link, img, short_text, categories]
    end
  end
end
