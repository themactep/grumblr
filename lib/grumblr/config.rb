require 'yaml'

module Grumblr
  class Config

    def initialize
      prepare_directory
    end

    def conf
      @@conf ||= YAML::load(open(config_file))
    rescue
      @@conf ||= {}
    end

    def get(name)
      conf[name.to_s]
    end

    def set(name, value)
      conf[name.to_s] = value
    end

    def save
      File.open(config_file, 'w') { |f| f.write conf.to_yaml }
    end

    def destroy
      @@conf = {}
      $app.quit
    end

    def config_file
      File.join(config_directory, 'settings.yml')
    end

    def config_directory
      @config_directory ||= File.expand_path(File.join('~', '.config', 'grumblr'))
    end

    def prepare_directory
      return if File.directory?(config_directory)
      FileUtils.mkdir_p(config_directory)
    end
  end
end
