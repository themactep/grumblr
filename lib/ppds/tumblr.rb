require 'ppds/class_factory'
require 'rest_client'
require 'xml'

module Ppds
  class User < ClassFactory
    attr_accessor :can_ask_question,
                  :can_upload_aiff,
                  :can_upload_audio,
                  :can_upload_video,
                  :default_post_format,
                  :liked_post_count,
                  :max_video_bytes_uploaded,
                  :vimeo_login_url
  end

  class Blog < ClassFactory
    attr_accessor :avatar_url,
                  :backup_post_limit,
                  :draft_count,
                  :followers,
                  :is_admin,
                  :is_primary,
                  :messages_count,
                  :name,
                  :posts,
                  :private_id,
                  :queue_count,
                  :title,
                  :twitter_enabled,
                  :type,
                  :url,
                # with include-theme=1:
                  :description,
                  :custom_css,
                  :theme_source
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
      'audio' => []
    }

    CONCURENT_FIELDS = {
      'text'  => [],
      'link'  => [],
      'chat'  => [],
      'quote' => [],
      'photo' => ['source', 'data'],
      'video' => ['embed', 'data'],
      'audio' => ['data', 'externally-hosted-url']
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

    DEFAULT_AVATAR = 'http://assets.tumblr.com/images/default_avatar_128.gif'

    def initialize
      self.user = nil
      self.blogs = []
    end

    def query(action, data)
      raise 'Cannot authenticate without credentials' unless data[:email] and data[:password]
      response = RestClient.post(API_URL + action, data.stringify_keys!)
      dump(response) if DEBUG
      response.to_str
    rescue RestClient::RequestFailed => e
      raise 'Query failed: %s' % e.response.body
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

    rescue Exception => e
      puts e
      false
    end
  end
end

class Hash
  # taken from Ruby on Rails
  # modified to replace undercores with dashes
  def stringify_keys!
    keys.each do |key|
      self[key.to_s.gsub(/_/, '-')] = delete(key)
    end
    self
  end
end
