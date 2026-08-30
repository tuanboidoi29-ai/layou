# TT - Layout PRO

**Version:** 1.0.0  
**Creator:** TRẦN TUẤN

## Mục tiêu
- Loader `SketchupExtension` chuẩn.
- SketchUp khởi động nhẹ: core chỉ nạp khi người dùng gọi plugin.
- Menu + toolbar + icon.
- Mỗi chức năng dùng callback Ruby thật.
- Nạp lại hệ thống không cần khởi động lại SketchUp.
- Kiểm tra/cập nhật từ GitHub.
- Phát hành RBZ bằng GitHub Actions.

## Cấu trúc
- `TT-Layout-PRO.rb` — loader đăng ký extension.
- `tt_layout_pro/core.rb` — lõi lazy-load và updater.
- `manifest.json` — version/update metadata.
- `tt_layout_pro/features/` — các chức năng mở rộng.
- `.github/workflows/release.yml` — đóng gói RBZ khi tạo tag `v*`.

## Phát hành
Tăng `VERSION` trong loader/core, cập nhật `manifest.json`, commit và tạo tag dạng `v1.0.1`. GitHub Actions sẽ đóng gói RBZ và tạo Release.

> Không đưa GitHub token vào plugin. RBZ chỉ chứa mã nguồn và tài nguyên cần thiết.
