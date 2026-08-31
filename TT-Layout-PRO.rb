# frozen_string_literal: true
require "sketchup.rb"
require "extensions.rb"

module TTLayoutPRO
  EXTENSION_NAME = "TT - Layout PRO"
  VERSION = "1.8.1"
  ROOT = File.join(__dir__, "TT-Layout-PRO")
  CORE = File.join(ROOT, "core.rb")

  unless defined?(@extension_registered) && @extension_registered
    extension = SketchupExtension.new(EXTENSION_NAME, CORE)
    extension.version = VERSION
    extension.creator = "TRẦN TUẤN"
    extension.description = "TT - Layout PRO: Layout A3/PDF, tên & kích thước ván, updater GitHub và reload không restart."
    Sketchup.register_extension(extension, false)

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
    @extension_registered = true
  end
end
