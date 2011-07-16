# encoding: utf-8

require 'ppds/tumblr'
require 'grumblr/config'
require 'grumblr/ui'
require 'gtk2'

module Grumblr

  class Core
    attr_accessor :blog

    def initialize
      $app = self

      $cfg = Grumblr::Config.new

      $gui = Grumblr::UI.new
      $gui.show_all

      $api = Ppds::Tumblr.new
      if $api.authenticate($cfg.get(:email), $cfg.get(:password))
        $gui.add Grumblr::Dashboard.new
      else
        $gui.add Grumblr::SettingsFrame.new
      end
    end

    def main
      Gtk::main
    end

    def quit
      Gtk::main_quit
    ensure
      $cfg.save
    end
  end
end
