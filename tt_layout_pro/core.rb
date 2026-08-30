# frozen_string_literal: true
require "sketchup.rb"
require "json"
require "uri"
require "net/http"
require "openssl"
require "tmpdir"

module TTLayoutPRO
  VERSION = "1.0.0"
  ROOT = File.dirname(__dir__)
  DATA_DIR = File.join(__dir__, "data")
  ICON_DIR = File.join(__dir__, "icons")
  FEATURE_DIR = File.join(__dir__, "features")
  MANIFEST_URL = "https://raw.githubusercontent.com/tuanboidoi29-ai/layou/main/manifest.json"

  @loaded = false
  @dialog = nil
  @commands = {}
  @menu = nil
  @toolbar = nil

  module_function

  def boot
    return if @loaded
    Dir.mkdir(DATA_DIR) unless Dir.exist?(DATA_DIR)
    Dir.mkdir(ICON_DIR) unless Dir.exist?(ICON_DIR)
    Dir.mkdir(FEATURE_DIR) unless Dir.exist?(FEATURE_DIR)
    register_ui
    load_features
    @loaded = true
  rescue => e
    UI.messagebox("TT - Layout PRO\nLỗi khởi động:\n#{e.class}: #{e.message}")
  end

  def register_ui
    return if @commands["main"]

    @commands["main"] = UI::Command.new("Bảng điều khiển") { open_dashboard }
    @commands["main"].tooltip = "Mở TT - Layout PRO"
    @commands["main"].status_bar_text = "TT - Layout PRO"
    @commands["main"].small_icon = File.join(ICON_DIR, "layout_16.png") if File.exist?(File.join(ICON_DIR, "layout_16.png"))
    @commands["main"].large_icon = File.join(ICON_DIR, "layout_24.png") if File.exist?(File.join(ICON_DIR, "layout_24.png"))

    @commands["update"] = UI::Command.new("Kiểm tra cập nhật") { check_update }
    @commands["update"].tooltip = "Kiểm tra phiên bản mới từ GitHub"
    @commands["update"].status_bar_text = "TT - Layout PRO: Kiểm tra cập nhật"

    @menu ||= UI.menu("Extensions").add_submenu("TT - Layout PRO")
    @menu.add_item(@commands["main"])
    @menu.add_separator
    @menu.add_item(@commands["update"])

    @toolbar ||= UI::Toolbar.new("TT - Layout PRO")
    @toolbar.add_item(@commands["main"])
    @toolbar.add_item(@commands["update"])
    @toolbar.show
  end

  def load_features
    Dir[File.join(FEATURE_DIR, "*.rb")].sort.each do |file|
      begin
        load file
      rescue => e
        puts("[TT - Layout PRO] #{File.basename(file)}: #{e.class}: #{e.message}")
      end
    end
  end

  def fetch_manifest
    uri = URI.parse(MANIFEST_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 8
    http.read_timeout = 12
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    response = http.get(uri.request_uri)
    raise "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  end

  def compare_versions(a, b)
    aa = a.to_s.split(".").map { |x| x.to_i }
    bb = b.to_s.split(".").map { |x| x.to_i }
    n = [aa.length, bb.length].max
    (0...n).each do |i|
      x = aa[i] || 0
      y = bb[i] || 0
      return 1 if x > y
      return -1 if x < y
    end
    0
  end

  def check_update
    boot
    begin
      manifest = fetch_manifest
      remote = manifest["version"].to_s
      if remote.empty?
        UI.messagebox("TT - Layout PRO\nKhông tìm thấy version trong manifest.")
        return
      end
      if compare_versions(remote, VERSION) <= 0
        UI.messagebox("TT - Layout PRO\nBạn đang dùng phiên bản mới nhất: #{VERSION}")
        return
      end

      url = manifest["download_url"].to_s
      if url.empty?
        UI.messagebox("Có phiên bản #{remote}, nhưng manifest chưa có download_url.")
        return
      end

      answer = UI.messagebox("Có phiên bản mới: #{remote}\nPhiên bản hiện tại: #{VERSION}\n\nCập nhật ngay?", MB_YESNO)
      return unless answer == IDYES
      download_and_install(url, remote)
    rescue => e
      UI.messagebox("TT - Layout PRO\nKhông thể kiểm tra cập nhật:\n#{e.class}: #{e.message}")
    end
  end

  def download_and_install(url, remote_version)
    uri = URI.parse(url)
    path = File.join(Dir.tmpdir, "TT-Layout-PRO-#{remote_version}.rbz")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 10
    http.read_timeout = 60
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    File.open(path, "wb") { |f| f.write(http.get(uri.request_uri).body) }
    raise "Tải file cập nhật thất bại" unless File.exist?(path) && File.size(path) > 100

    unless Sketchup.respond_to?(:install_from_archive)
      UI.messagebox("SketchUp hiện tại không hỗ trợ install_from_archive qua Ruby API.\nFile đã tải tại:\n#{path}")
      return
    end

    Sketchup.install_from_archive(path, true)
    reload_system
    UI.messagebox("TT - Layout PRO\nĐã cài phiên bản #{remote_version}.\nĐã yêu cầu nạp lại hệ thống, không cần khởi động lại SketchUp.")
  end

  def reload_system
    @loaded = false
    load File.join(__dir__, "core.rb")
    boot
  rescue => e
    UI.messagebox("Nạp lại thất bại:\n#{e.class}: #{e.message}")
  end

  def open_dashboard
    boot
    @dialog ||= UI::HtmlDialog.new(
      dialog_title: "TT - Layout PRO",
      preferences_key: "TT_LAYOUT_PRO",
      scrollable: true,
      resizable: true,
      width: 760,
      height: 620,
      style: UI::HtmlDialog::STYLE_DIALOG
    )
    @dialog.set_html(dashboard_html)
    @dialog.add_action_callback("update") { check_update }
    @dialog.add_action_callback("reload") { reload_system }
    @dialog.add_action_callback("close") { @dialog.close }
    @dialog.show
  end

  def dashboard_html
    <<~HTML
      <!doctype html><html><head><meta charset="utf-8"><style>
      body{margin:0;background:#20252b;color:#fff;font-family:Arial;padding:24px}h1{margin:0 0 6px;font-size:24px}.sub{opacity:.7;margin-bottom:22px}.grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}button{border:0;border-radius:8px;padding:16px;background:#34495e;color:#fff;font-weight:bold;cursor:pointer}button:hover{background:#4b6584}.wide{grid-column:1/-1}.info{margin-top:20px;padding:14px;background:#111820;border-radius:8px;font-size:12px;line-height:1.7}
      </style></head><body><h1>TT - Layout PRO</h1><div class="sub">Lazy Load • Callback Ruby • GitHub Update • Reload không restart</div><div class="grid"><button onclick="sketchup.update()">🔄 Kiểm tra cập nhật</button><button onclick="sketchup.reload()">♻️ Nạp lại hệ thống</button><button class="wide" onclick="sketchup.close()">ĐÓNG</button></div><div class="info"><b>Phiên bản:</b> #{VERSION}<br><b>Khởi động:</b> Lazy / On-demand<br><b>Cập nhật:</b> GitHub manifest<br><b>Nguyên tắc:</b> không chạy nền khi người dùng chưa gọi chức năng</div></body></html>
    HTML
  end
end

TTLayoutPRO.boot
