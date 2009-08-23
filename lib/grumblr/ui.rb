require 'gtk2'

module Grumblr

  DATA_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'data'))

  class UI < Gtk::Window

    attr_accessor :logo

    def initialize
      super Gtk::Window::TOPLEVEL

      filename = File.join(Grumblr::DATA_ROOT, 'pixmaps', 'grumblr.svg')
      self.logo = Gdk::Pixbuf.new filename, 128, 128

      self.set_size_request 480, 360
      self.set_allow_shrink false
      self.set_title 'Grumblr'

      self.set_icon self.logo
      self.set_default_width $cfg.get(:window_width).to_i
      self.set_default_height $cfg.get(:window_height).to_i
      self.move $cfg.get(:window_x_pos).to_i, $cfg.get(:window_y_pos).to_i
      self.signal_connect(:destroy) { quit }
      self.signal_connect(:delete_event) { minimize }
      self.signal_connect(:check_resize) do |widget|
        x, y = widget.position
        w, h = widget.size
        $cfg.set :window_x_pos, x
        $cfg.set :window_y_pos, y
        $cfg.set :window_width, w
        $cfg.set :window_height, h
      end
      signal_connect(:window_state_event) do |widget, e|
        case e.event_type
        when Gdk::Event::WINDOW_STATE
          minimize if e.changed_mask.iconified? and e.new_window_state.iconified?
        end
      end
      show
    end

    def minimize
      self.hide
    end
  end

  class Dashboard < Gtk::VBox
    def initialize
      super false, 4

      ##
      ### Statusbar
      ##
      @statusbar = Gtk::Statusbar.new

      ##
      ### Notebook
      ##
      @notebook = Gtk::Notebook.new
      @notebook.set_homogeneous true
      @notebook.set_tab_pos Gtk::POS_LEFT

      #
      # Text page
      #
      @text_title = Gtk::Entry.new

      @format = Gtk::CheckButton.new '_markdown'
      @format.set_active $cfg.get(:format_markdown)
      @format.signal_connect(:toggled) do |widget|
        $cfg.set :format_markdown, widget.active?
      end

      label = Gtk::Label.new 'Body'

      box = Gtk::HBox.new false, 8
      box.pack_start label, false
      box.pack_start @format, false

      page = Gtk::VBox.new false, 4
      page.set_border_width 8
      page.pack_with_label 'Title (optional)', @text_title
      page.pack_start box, false
      page.pack_start multiline_entry(:text_body), true

      @notebook.add_page_with_tab page, 'Text'

      #
      # Link page
      #
      @link_url = Gtk::Entry.new
      @link_name = Gtk::Entry.new
      link_description = multiline_entry :link_description

      page = Gtk::VBox.new false, 4
      page.set_border_width 8
      page.pack_with_label 'URL', @link_url
      page.pack_with_label 'Name (optional)', @link_name
      page.pack_with_label'Description (optional)', link_description, true

      @notebook.add_page_with_tab page, 'Link'

      #
      # Chat page
      #
      @chat_title = Gtk::Entry.new
      chat_conversation = multiline_entry :chat_conversation

      page = Gtk::VBox.new false, 4
      page.set_border_width 8
      page.pack_with_label 'Title (optional)', @chat_title
      page.pack_with_label 'Conversation', chat_conversation, true

      @notebook.add_page_with_tab page, 'Chat'

      #
      # Quote page
      #
      @quote_source = Gtk::Entry.new
      quote_quote = multiline_entry :quote_quote

      page = Gtk::VBox.new false, 4
      page.set_border_width 8
      page.pack_with_label 'Quote', quote_quote, true
      page.pack_with_label 'Source (optional)', @quote_source

      @notebook.add_page_with_tab page, 'Quote'

      #
      # Photo page
      #
      filter = Gtk::FileFilter.new
      filter.set_name "Images"
      filter.add_mime_type "image/*"

      @photo_source = Gtk::Entry.new
      @photo_click_through_url = Gtk::Entry.new
      photo_data = file_chooser_button :photo_data, filter
      photo_caption = multiline_entry :photo_caption

      page = Gtk::VBox.new false, 4
      page.set_border_width 8
      page.pack_with_label 'File', photo_data
      page.pack_with_label 'Source', @photo_source
      page.pack_with_label 'Caption', photo_caption, true
      page.pack_with_label 'Link (optional)', @photo_click_through_url

      @notebook.add_page_with_tab page, 'Photo'

      #
      # Audio page
      #
      if $api.user.can_upload_audio == '1'
        filter = Gtk::FileFilter.new
        filter.set_name "Audio"
        filter.add_mime_type "audio/*"

        audio_data = file_chooser_button :audio_data, filter
        audio_caption = multiline_entry :audio_caption

        page = Gtk::VBox.new false, 4
        page.set_border_width 8
        page.pack_with_label 'File', audio_data
        page.pack_with_label 'Caption (optional)', audio_caption, true

        @notebook.add_page_with_tab page, 'Audio'
      end

      #
      # Video page
      #
      @video_embed = Gtk::Entry.new
      video_caption = multiline_entry :video_caption

      page = Gtk::VBox.new false, 4
      page.set_border_width 8

      if $api.user.can_upload_video == '1'
        filter = Gtk::FileFilter.new
        filter.set_name "Video"
        filter.add_mime_type "video/*"

        video_data = file_chooser_button :video_data, filter
        @video_title = Gtk::Entry.new

        page.pack_with_label 'File', video_data
        page.pack_with_label 'Title (optional)', @video_title
      end

      page.pack_with_label 'Embed code / YouTube link', @video_embed
      page.pack_with_label 'Caption (optional)', video_caption, true

      @notebook.add_page_with_tab page, 'Video'

      ##
      ### Toolbar
      ##

      toolbar = Gtk::Toolbar.new
      toolbar.icon_size = Gtk::IconSize::MENU

      icon = Gtk::Image.new Gtk::Stock::HOME, Gtk::IconSize::MENU
      item = Gtk::ToolButton.new icon, 'Tumblelog'
      item.signal_connect(:clicked) do
        Thread.new { system('xdg-open "%s"' % $app.blog.url) }
      end
      toolbar.insert 0, item

      icon = Gtk::Image.new Gtk::Stock::PREFERENCES, Gtk::IconSize::MENU
      item = Gtk::ToolButton.new icon, 'Dashboard'
      item.signal_connect(:clicked) do
        Thread.new { system('xdg-open "http://www.tumblr.com/tumblelog/%s"' % $app.blog.name) }
      end
      toolbar.insert 1, item

      combo = Gtk::ComboBox.new
      active_blog = $cfg.get(:active_blog) || nil
      active_blog_idx = nil
      $api.blogs.each_with_index do |blog, idx|
        combo.append_text blog.title
        active_blog_idx = idx if blog.name.eql?(active_blog)
        active_blog_idx = idx if active_blog_idx.nil? and blog.is_primary == "yes"
      end
      combo.signal_connect(:changed) do |widget|
        $app.blog = $api.blogs[widget.active]
        $cfg.set :active_blog, $app.blog.name
        @statusbar.push 0, $app.blog.title
      end
      combo.set_active(active_blog_idx)
      item =  Gtk::ToolItem.new
      item.set_expand true
      item.add combo
      toolbar.insert 2, item

      icon = Gtk::Image.new Gtk::Stock::QUIT, Gtk::IconSize::MENU
      item = Gtk::ToolButton.new icon, 'Quit'
      item.set_homogeneous false
      item.signal_connect(:clicked) do
        $app.quit
      end
      toolbar.insert 3, item

      ##
      ### Buttons
      ##
      clear_button = Gtk::Button.new 'Clear'
      clear_button.set_focus_on_click false
      clear_button.signal_connect(:clicked) do |widget|
        page = @notebook.get_nth_page @notebook.page
        message_type = @notebook.get_menu_label_text page
        reset_form message_type.downcase
      end

      @private_button = Gtk::ToggleButton.new 'Private'
      @private_button.signal_connect(:toggled) do |widget|
        $cfg.set :private, widget.active?
      end
      @private_button.set_active $cfg.get(:private)

      submit_button = Gtk::Button.new 'Send'
      submit_button.signal_connect(:released) do |widget|
        post
      end

      button_box = Gtk::HBox.new false, 4
      button_box.pack_start clear_button, false
      button_box.pack_start @private_button, false
      button_box.pack_start submit_button

      ##
      ### Layout
      ##
      pack_start toolbar, false
      pack_start @notebook
      pack_start button_box, false
      pack_start @statusbar, false
      show_all
    end

    def post
      page = @notebook.get_nth_page @notebook.page
      message_type = @notebook.get_menu_label_text(page).downcase

      mandatory_data = collect_data_for Ppds::Tumblr::MANDATORY_FIELDS, message_type
      concurent_data = collect_data_for Ppds::Tumblr::CONCURENT_FIELDS, message_type
      optional_data  = collect_data_for Ppds::Tumblr::OPTIONAL_FIELDS,  message_type

      mandatory_data.each do |key, value|
        raise "Mandatory field %s is not set!" % key if not value or value.empty?
      end unless Ppds::Tumblr::MANDATORY_FIELDS[message_type].empty?

      unless Ppds::Tumblr::CONCURENT_FIELDS[message_type].empty?
        concurent_data.delete_if { |x,y| y == "" or y.nil? }
        raise "None of fields %s is set!" % Ppds::Tumblr::CONCURENT_FIELDS[message_type].join(", ") if concurent_data.empty?
      end

      optional_data.delete_if { |x,y| y == "" or y.nil? }

      data = {
        :generator  => 'Grumblr',
        :email      => $cfg.get(:email),
        :password   => $cfg.get(:password),
        :channel_id => $app.blog.name,
        :group      => $app.blog.name + '.tumblr.com',
        :type       => message_type,
        :format     => @format.active? ? 'markdown' : 'html',
        :private    => @private_button.active? ? 1 : 0
      }

      data.merge! mandatory_data
      data.merge! concurent_data
      data.merge! optional_data

      data.update({:data => File.read(data['data'])}) if data.has_key?('data') and data['data'] != ""

      $api.query 'write', data
      MessageDialog.new "Message posted", Gtk::Stock::DIALOG_INFO
      reset_form message_type
    rescue Exception
      MessageDialog.new $!
    end

    def collect_data_for(fieldset, message_type)
      data = {}
      for key in fieldset[message_type]
        name = "@#{message_type}_#{key.gsub(/-/,'_')}"
        if var = instance_variable_get(name)
          value = var.get_value
          data.merge!({ key => value })
        end
      end
      data
    end

    def file_chooser_button(name, filter = nil)
      button = Gtk::FileChooserButton.new('Open', Gtk::FileChooser::ACTION_OPEN)
      if filter
        button.add_filter(filter)
        button.set_filter(filter)
      end
      button.signal_connect(:selection_changed) do |widget|
        puts widget.filename
      end
      button.show_all
      instance_variable_set "@#{name}", button
    end

    def multiline_entry(name)
      instance_variable_set "@#{name}", Gtk::TextBuffer.new

      view = Gtk::TextView.new
      view.set_buffer instance_variable_get("@#{name}")
      view.set_wrap_mode Gtk::TextTag::WRAP_WORD
      view.set_right_margin 5
      view.set_left_margin 5

      window = Gtk::ScrolledWindow.new
      window.set_shadow_type Gtk::SHADOW_IN
      window.set_policy Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC
      window.add view
      window.show_all
    end

    def reset_fields_for(fieldset, message_type)
      for key in fieldset[message_type]
        name = "@#{message_type}_#{key.gsub(/-/,'_')}"
        var = instance_variable_get(name)
        var.clear if var
      end
    end

    def reset_form(message_type)
      [ Ppds::Tumblr::MANDATORY_FIELDS,
        Ppds::Tumblr::CONCURENT_FIELDS,
        Ppds::Tumblr::OPTIONAL_FIELDS ].each do |fieldset|
        reset_fields_for(fieldset, message_type)
      end
    end
  end

  class MessageDialog < Gtk::Dialog
    def initialize(text, stock = Gtk::Stock::DIALOG_ERROR)
      super "Attention!", $gui, Gtk::Dialog::MODAL

      message = Gtk::Label.new text
      icon = Gtk::Image.new stock, Gtk::IconSize::DIALOG

      hbox = Gtk::HBox.new false, 20
      hbox.set_border_width 20
      hbox.pack_start icon, false
      hbox.pack_start message, true

      self.add_button Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE
      self.signal_connect(:response) { self.destroy }
      self.vbox.add hbox
      self.show_all
      self.run
    end
  end

  class SettingsFrame < Gtk::HBox
    def initialize
      super false, 40
      self.set_border_width 40

      @label = Gtk::Label.new
      @label.set_markup '<b>Fill-in Tumblr credentials</b>'

      @text_e = Gtk::Entry.new
      @text_e.set_text $cfg.get(:email).to_s

      @text_p = Gtk::Entry.new
      @text_p.set_visibility false
      @text_p.set_text $cfg.get(:password).to_s

      hbox = Gtk::HBox.new

      button = Gtk::Button.new 'Cancel'
      button.signal_connect(:released) { $app.quit }
      hbox.pack_start button

      button = Gtk::Button.new 'Sign in'
      button.signal_connect(:released) { login }
      hbox.pack_start button

      header = Gtk::Label.new
      header.set_alignment 0.0, 0.8
      header.set_markup '<big><big><b>Grumblr 2.0</b></big></big>'

      vbox = Gtk::VBox.new false, 4
      vbox.pack_start header
      vbox.pack_with_label '_Email', @text_e
      vbox.pack_with_label '_Password', @text_p
      vbox.pack_start @label
      vbox.pack_start hbox, false

      logo = Gtk::Image.new $gui.logo

      self.pack_start logo
      self.pack_start vbox
      self.show_all
    end

    def login
      email = @text_e.text.strip
      password = @text_p.text.strip
      if $api.authenticate(email, password)
        $cfg.set :email, email
        $cfg.set :password, password
        self.destroy
        @dashboard = Dashboard.new
        $gui.add @dashboard
      else
        raise "Authentication failed"
      end
    rescue Exception
      MessageDialog.new $!
    end
  end


  class AboutDialog < Gtk::AboutDialog
    def initialize
      Gtk::AboutDialog.set_email_hook do |dialog, email|
        system("xdg-email #{email}")
      end
      Gtk::AboutDialog.set_url_hook do |dialog, url|
        system("xdg-open #{url}")
      end
      super
      self.logo          = $gui.logo
      self.program_name  = 'Grumblr'
      self.version       = '2.0.0'
      self.copyright     = "Copyright (c)2009, Paul Philippov"
      self.comments      = "Tumblr companion for GNOME"
      self.license       = "New BSD License.\nhttp://creativecommons.org/licenses/BSD/"
      self.website       = "http://themactep.com/grumblr/"
      self.authors       = ['Paul Philippov <themactep@gmail.com>']
      self.run
      self.destroy
    end
  end

  class StatusIcon < Gtk::StatusIcon
    def initialize
      super
      self.file = File.join(Grumblr::DATA_ROOT, 'pixmaps', 'grumblr.svg')
      self.tooltip = "Application Name Goes Here"
      self.signal_connect(:activate) do
        if $gui.visible?
          $gui.minimize
        else
          $gui.move $cfg.get(:window_x_pos), $cfg.get(:window_y_pos)
          $gui.show.present
        end
      end
      self.signal_connect(:popup_menu) do |icon, button, time|
        menu.popup nil, nil, button, time
      end
    end

    def menu
      menu = Gtk::Menu.new
      for item in [ ontop, sep, destroy_account, sep, about, sep, quit ]
        menu.append item
      end
      menu.show_all
    end

    def sep
      Gtk::SeparatorMenuItem.new
    end

    ##
    ## Destroy Config
    ##
    def destroy_account
      icon = Gtk::ImageMenuItem.new 'Destroy account'
      icon.set_image Gtk::Image.new(Gtk::Stock::STOP, Gtk::IconSize::MENU)
      icon.signal_connect(:activate) do
        $cfg.destroy
      end
      icon.show
    end

    def about
      icon = Gtk::ImageMenuItem.new Gtk::Stock::ABOUT
      icon.signal_connect(:activate) do
        AboutDialog.new
      end
      icon.show
    end

    def ontop
      icon = Gtk::CheckMenuItem.new 'Always on top'
      icon.signal_connect(:toggled) do |widget|
        $gui.keep_above = widget.active?
      end
      icon.show
    end

    def quit
      icon = Gtk::ImageMenuItem.new Gtk::Stock::QUIT
      icon.signal_connect(:activate) do
        $app.quit
      end
      icon.show
    end
  end
end

class Gtk::Box
  def pack_with_label(text, widget, expand = false)
    label = Gtk::Label.new text, true
    label.set_alignment 0.0, 0.5
    label.set_mnemonic_widget widget
    self.pack_start label, false
    self.pack_start widget, expand
  end
end

class Gtk::Entry
  alias :get_value :text
  def clear
    self.set_text ''
  end
end

module Gtk::FileChooser
  alias :get_value :filename
  alias :clear :unselect_all
end

class Gtk::Notebook
  def add_page_with_tab(page, text)
    filename = File.join(Grumblr::DATA_ROOT, 'pixmaps', '%s.bmp' % text.downcase)
    icon = Gtk::Image.new filename
    icon.set_padding 2, 4

    label = Gtk::Label.new '_' + text, true
    label.set_alignment 0.0, 0.5
    label.set_padding 4, 2

    box = Gtk::HBox.new false, 4
    box.pack_start icon, false
    box.pack_start label, true
    box.show_all

    self.append_page_menu page, box, label
  end
end

class Gtk::TextBuffer
  alias :get_value :get_text
  def clear
    self.set_text ''
  end
end
