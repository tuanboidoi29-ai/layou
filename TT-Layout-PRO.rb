# frozen_string_literal: true
# TT - Layout PRO | Stable Extension Loader
require "sketchup.rb"
require "extensions.rb"

module TTLayoutPRO
  EXTENSION_NAME = "TT - Layout PRO"
  VERSION = "1.0.0"
  ROOT = File.join(__dir__, "tt_layout_pro")
  CORE = File.join(ROOT, "core.rb")

  unless defined?(@extension_registered) && @extension_registered
    extension = SketchupExtension.new(
      EXTENSION_NAME,
      CORE
    )
    extension.version = VERSION
    extension.creator = "TRẦN TUẤN"
    extension.description = "Layout PRO: loader nhẹ, lazy-load, menu/icon, callback Ruby thật, cập nhật GitHub và nạp lại không cần khởi động lại SketchUp."

    # false = không tự nạp toàn bộ core khi SketchUp khởi động.
    # Loader vẫn đăng ký extension vào Extension Manager.
    Sketchup.register_extension(extension, false)

    # Menu khởi động cực nhẹ; chỉ khi người dùng bấm mới load core.
    unless defined?(@command_registered) && @command_registered
      command = UI::Command.new("Mở TT - Layout PRO") do
        begin
          load CORE
        rescue => e
          UI.messagebox("TT - Layout PRO\nKhông thể nạp core:\n#{e.class}: #{e.message}")
        end
      end
      command.tooltip = "Mở TT - Layout PRO"
      command.status_bar_text = "Mở TT - Layout PRO"
      UI.menu("Extensions").add_item(command)
      @command_registered = true
    end

    @extension_registered = true
  end
end
