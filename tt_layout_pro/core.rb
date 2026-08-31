# frozen_string_literal: true
require "sketchup.rb"
require "json"
require "uri"
require "net/http"
require "openssl"
require "tmpdir"
require "fileutils"

module TTLayoutPRO
  VERSION = "1.8.1"
  ROOT = File.dirname(__dir__)
  DATA_DIR = File.join(__dir__, "data")
  ICON_DIR = File.join(__dir__, "icons")
  FEATURE_DIR = File.join(__dir__, "features")
  RELEASE_API = "https://api.github.com/repos/tuanboidoi29-ai/layou/releases/latest"

  @loaded = false
  @commands = {}

  module_function

  def boot
    return if @loaded
    FileUtils.mkdir_p(DATA_DIR)
    FileUtils.mkdir_p(ICON_DIR)
    FileUtils.mkdir_p(FEATURE_DIR)
    load_features
    @loaded = true
  end

  def load_features
    Dir[File.join(FEATURE_DIR, "*.rb")].sort.each do |file|
      begin
        load file
      rescue => e
        puts "[TT - Layout PRO] #{File.basename(file)}: #{e.class}: #{e.message}"
      end
    end
  end

  def start_layout
    boot
    TTLayoutPRO::LayoutEngine.new.start
  rescue => e
    UI.messagebox("TT - Layout PRO\nLỗi Layout:\n#{e.class}: #{e.message}\n\n#{e.backtrace.first(8).join("\n")}")
  end

  def http_get(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 8
    http.read_timeout = 60
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    req = Net::HTTP::Get.new(uri.request_uri)
    req["User-Agent"] = "TT-Layout-PRO/#{VERSION}"
    req["Accept"] = "application/vnd.github+json"
    res = http.request(req)
    raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
    res
  end

  def latest_release
    JSON.parse(http_get(RELEASE_API).body)
  end

  def version_parts(v)
    v.to_s.sub(/\Av/i, "").split(".").map { |x| x.to_i }
  end

  def newer?(remote, local)
    a = version_parts(remote); b = version_parts(local)
    n = [a.length, b.length].max
    (0...n).each do |i|
      x = a[i] || 0; y = b[i] || 0
      return true if x > y
      return false if x < y
    end
    false
  end

  def check_update
    begin
      release = latest_release
      remote = release["tag_name"].to_s.sub(/\Av/i, "")
      raise "Release không có tag version" if remote.empty?
      unless newer?(remote, VERSION)
        UI.messagebox("TT - Layout PRO\nBạn đang dùng bản mới nhất: v#{VERSION}")
        return
      end

      asset = Array(release["assets"]).find { |a| a["name"].to_s.downcase.end_with?(".rbz") }
      raise "Release mới không có file RBZ" unless asset
      answer = UI.messagebox("TT - Layout PRO\n\nCó bản mới: v#{remote}\nĐang dùng: v#{VERSION}\n\nTải và cài ngay?", MB_YESNO)
      return unless answer == IDYES
      download_and_install(asset["browser_download_url"].to_s, remote, asset["name"].to_s)
    rescue => e
      UI.messagebox("TT - Layout PRO\nKhông thể kiểm tra cập nhật:\n#{e.class}: #{e.message}")
    end
  end

  def download_and_install(url, remote, filename)
    raise "URL RBZ không hợp lệ" unless url.start_with?("https://github.com/")
    path = File.join(Dir.tmpdir, filename)
    res = http_get(url)
    File.binwrite(path, res.body)
    raise "File RBZ tải về không hợp lệ" unless File.exist?(path) && File.size(path) > 1000

    unless Sketchup.respond_to?(:install_from_archive)
      UI.messagebox("TT - Layout PRO\nSketchUp không hỗ trợ install_from_archive.\nFile đã tải:\n#{path}")
      return
    end

    Sketchup.install_from_archive(path, true)
    UI.messagebox("TT - Layout PRO\nĐã tải và cài RBZ v#{remote}.\nHệ thống sẽ nạp lại theo cơ chế của SketchUp.")
  end

  def reload_system
    @loaded = false
    load File.join(__dir__, "core.rb")
    boot
    UI.messagebox("TT - Layout PRO\nĐã nạp lại hệ thống.")
  rescue => e
    UI.messagebox("TT - Layout PRO\nLỗi nạp lại:\n#{e.class}: #{e.message}")
  end

  def register_ui
    return if @ui_registered
    main = UI::Command.new("Xuất Layout PDF") { start_layout }
    main.tooltip = "Tạo hồ sơ Layout A3 và xuất PDF"
    main.status_bar_text = "TT - Layout PRO: Xuất Layout PDF"
    s = File.join(ICON_DIR, "layout_16.png"); l = File.join(ICON_DIR, "layout_24.png")
    main.small_icon = s if File.exist?(s); main.large_icon = l if File.exist?(l)

    update = UI::Command.new("Kiểm tra cập nhật") { check_update }
    update.tooltip = "Kiểm tra bản phát hành mới từ GitHub"
    us = File.join(ICON_DIR, "update_16.png"); ul = File.join(ICON_DIR, "update_24.png")
    update.small_icon = us if File.exist?(us); update.large_icon = ul if File.exist?(ul)

    menu = UI.menu("Extensions").add_submenu("TT - Layout PRO")
    menu.add_item(main); menu.add_item(update)
    tb = UI::Toolbar.new("TT - Layout PRO")
    tb.add_item(main); tb.add_item(update); tb.show
    @commands["main"] = main; @commands["update"] = update; @toolbar = tb; @ui_registered = true
  end

  register_ui
end

TTLayoutPRO.boot
