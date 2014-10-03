require 'poster/encoding'
require 'poster/site'

module Poster
  # Represents an internet forum (like Bitcointalk) 
  class Forum < Site

    def initialize url:, **opts
      super
      login if @opts[:user] && @opts[:pass] && @opts[:login_path]
    end

    # Login to site
    def login
      post @opts[:login_path],
        body: {user: @opts[:user], passwrd: @opts[:pass]},
        content_type: 'application/x-www-form-urlencoded'
    end

    # Post new topic
    def new_topic board: 92, subj: 'test', msg: 'msg', icon: "exclamation"
      board = board.instance_of?(Symbol) ? @opts[:boards][board] : board
      # Check board posting page first (to get sequence numbers)
      get "/index.php?action=post;board=#{board}.0"

      raise "Not logged, cannot post!" unless logged?
      p msg
      # Create new post
      seqnum, sc = find_fields 'seqnum', 'sc'
      subj = xml_encode(subj_encode(subj))
      msg = xml_encode(msg)
      # p subj, msg
      # exit
      post "/index.php?action=post2;start=0;board=#{board}",
        content_type: 'multipart/form-data; charset=ISO-8859-1',
        body: { topic: 0, subject: subj, icon: icon, message: msg,
                notify: 0, do_watch: 0,  selfmod: 0, lock: 0, goback: 1, ns: "NS", post: "Post",
                additional_options: 0, sc: sc, seqnum: seqnum },
        options: {timeout: 5}   # open/read timeout in seconds
      
      # Make sure the message was posted, return topic page
      new_topic = @response.headers['location']
      # p @response.body
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

  end
end
