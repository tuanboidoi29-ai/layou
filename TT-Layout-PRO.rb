# frozen_string_literal: true
# TT - Layout PRO | Stable Extension Loader
require "sketchup.rb"
require "extensions.rb"

module TTLayoutPRO
  EXTENSION_NAME = "TT - Layout PRO"
  VERSION = "1.0.0"
  ROOT = File.join(__dir__, "tt_layout_pro")

  unless defined?(@extension_registered) && @extension_registered
    extension = SketchupExtension.new(
      EXTENSION_NAME,
      File.join(ROOT, "core.rb")
    )
    extension.version = VERSION
    extension.creator = "TRẦN TUẤN"
    extension.description = "Layout PRO: lazy-load, menu/icon, callback Ruby thật, cập nhật GitHub và nạp lại không cần khởi động lại SketchUp."
    Sketchup.register_extension(extension, true)
    @extension_registered = true
  end
end
