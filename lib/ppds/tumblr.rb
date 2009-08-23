require 'ppds/class_factory'
require 'rest_client'
require 'xml'

module Ppds
  class User < ClassFactory
    attr_accessor :default_post_format, :can_upload_audio, :can_upload_aiff,
                  :can_upload_video, :vimeo_login_url, :max_video_bytes_uploaded
  end

  class Blog < ClassFactory
    attr_accessor :type, :title, :name, :url, :avatar_url,
                  :is_primary, :private_id
  end

  class Tumblr
    attr_accessor :user, :blogs

    MANDATORY_FIELDS = {
      'text'  => ['body'],
      'link'  => ['url'],
      'chat'  => ['conversation'],
      'quote' => ['quote'],
      'photo' => [],
      'video' => [],
      'audio' => ['data']
    }

    CONCURENT_FIELDS = {
      'text'  => [],
      'link'  => [],
      'chat'  => [],
      'quote' => [],
      'photo' => ['source', 'data'],
      'video' => ['embed', 'data'],
      'audio' => []
    }

    OPTIONAL_FIELDS  = {
      'text'  => ['title'],
      'link'  => ['name', 'description'],
      'chat'  => ['title'],
      'quote' => ['source'],
      'photo' => ['caption','click-through-url'],
      'video' => ['caption'], # 'title'
      'audio' => ['caption']
    }

    API_URL = 'http://www.tumblr.com/api/'

    def initialize
      self.user = nil
      self.blogs = []
    end

    def query(action, data)
      RestClient.post(API_URL + action, data)
    rescue RestClient::RequestFailed
      raise 'Query failed: %s' % $!
    rescue RestClient::RequestTimeout
      raise 'Timeout occured'
    rescue Exception
      raise $!
    end

    def authenticate(email, password)
      data = {
        :email    => email,
        :password => password
      }
      xml = query('authenticate', data)
      @xml = XML::Parser.string(xml).parse

      self.user  = User.new(@xml.find_first('//tumblr/user').attributes) if @xml
      self.blogs = @xml.find('//tumblr/tumblelog').map do |node|
        Blog.new(node.attributes)
      end

      true

    rescue Exception
      false
    end
  end
end
