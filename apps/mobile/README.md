# Little Island — Flutter app

Giai đoạn local của app nhắc uống nước tiếng Việt. Đã dựng Android/iOS và web để kiểm tra giao diện. Bộ nguồn chạy bằng Flutter 3.47.8 / Dart 3.13.7; phiên bản package thực tế được khóa trong `pubspec.lock`.

## Chạy từ thư mục gốc repository

```powershell
./scripts/flutter.ps1 pub get
./scripts/flutter.ps1 run -d chrome
```

Script ưu tiên SDK tại `.tools/flutter`, nếu không có sẽ tìm `flutter` trong PATH. SDK local được tải từ repository Flutter chính thức, không đưa vào Git.

Android: đã build và chạy APK debug x86_64 trên Medium Phone API 37. Từ thư mục gốc chạy `./scripts/run-mobile.ps1` để nối Supabase local; emulator dùng `10.0.2.2:15421`. Xem [OAuth setup](../../document/oauth-setup.md). Script `scripts/flutter.ps1` vẫn dùng được cho bản local không cấu hình backend.

iOS: chuyển source sang máy macOS có Xcode, cấu hình signing và chạy bằng Flutter. Chưa xác minh build/sign iOS trên máy Windows.

## Sinh mã và kiểm tra

Trong thư mục `apps/mobile`:

```sh
dart run build_runner build
flutter analyze
flutter test
dart compile js web/drift_worker.dart -o web/drift_worker.dart.js
flutter build web --release
```

Worker và sqlite3.wasm được giữ trong `web/` để bản web mở database offline. Khi đổi Drift hoặc SQLite, biên dịch lại worker và thay WASM đúng phiên bản; không ghép phiên bản tùy ý. WASM hiện lấy từ release `sqlite3-3.5.2` chính thức của sqlite3.dart.

Xuất ảnh QA tùy chọn: `flutter test test/app_flow_test.dart --dart-define=CAPTURE_UI=true`. Ảnh ghi vào `document/qa/` của repository.

## Chức năng hiện có

- Lần đầu thiết lập mục tiêu nhập tay, hồ sơ, khung giờ.
- Ghi nhận dung tích nhanh hoặc tùy chọn; sửa/xóa/hoàn tác.
- Tiến độ ngày, lịch sử 7 ngày, chuỗi ngày đạt mục tiêu.
- Mèo Mochi, chó Biscuit và cá Bubbles; chọn trong Cá nhân và đồng bộ lựa chọn. Ba giai đoạn tăng trưởng và phản hồi chạm/cho ăn; phần thưởng local có giới hạn, được tính lại khi hoàn tác.
- SQLite và outbox giao dịch; đồng bộ hồ sơ, mục tiêu và lịch sử với Supabase, retry idempotent, revision conflict và tombstone. Database tách theo tài khoản; đăng xuất trở về khách.
- UI Google/Apple/Facebook qua PKCE và liên kết identity, chờ cấu hình credentials; nhập dữ liệu khách có xác nhận. Phiên native lưu trong secure storage.
- Local notifications Android/iOS, cần người dùng cấp quyền. Lịch inexact có thể trễ theo OS; horizon tối đa 7 ngày rồi bổ sung khi mở app. Receiver Android khôi phục lịch sau reboot/đổi giờ/đổi múi giờ; adapter pin plugin 22.3.3.
- Ba nút điều hướng chỉ có icon; nhãn hỗ trợ tiếp cận vẫn giữ.

## Phạm vi kiểm chứng

- Kiểm thử nghiệp vụ, SQLite, luồng app và bố cục 360×800, 390×844, 414×896.
- Web build dùng cùng mã Flutter; lưu IndexedDB/OPFS theo khả năng trình duyệt. Không hỗ trợ nhắc nền web.
- Thông báo khi đóng app/reboot và OAuth cần kiểm tra trên Android/iPhone thật, chưa được xác minh bằng widget test.

## Còn lại

Supabase local đã kết nối. Còn credentials/kiểm chứng OAuth thật, deploy VPS, hợp nhất hai tài khoản có sẵn, xóa tài khoản và server-authoritative rewards. Xem `document/implementation-status.md`. Không đưa service key vào app.

Kiểm thử từ thư mục gốc:

```powershell
./scripts/backend.ps1 Test
./scripts/test-mobile-sync.ps1
./scripts/test-mobile-android.ps1
```

Kiểm thử tạo tài khoản synthetic rồi dọn dữ liệu. `-LocalAuth` của `run-mobile.ps1` chỉ bật đăng nhập email thử trong debug với backend local; không tạo tài khoản thật hoặc thay thế OAuth production. Giao thức và giới hạn: [sync-protocol.md](../../document/sync-protocol.md).

Application ID `com.littleisland.little_island` là tạm, release Android hiện còn signing debug của template; chưa dùng để phát hành.

## Asset và bản quyền

Giai đoạn 3 thêm icon SVG gốc, icon native/web và splash; chó/cá vẽ bằng CustomPainter. Hồ sơ local schema v3 thêm `pet`, backend migration `202610290002_pet_preferences.sql` bổ sung lựa chọn này vào profile/RPC.

Chuẩn bị phát hành: [release-checklist.md](../../document/release-checklist.md). `scripts/build-release.ps1 -ValidateOnly` liệt kê điều kiện còn thiếu; release không tự ký bằng khóa debug. `scripts/build-unsigned-qa.ps1` chỉ kiểm tra AAB unsigned, không publish. Quyền riêng tư/điều khoản/thông tin xóa dữ liệu trong app là dự thảo; xóa toàn bộ tài khoản chưa triển khai theo lựa chọn của người dùng.

Ảnh và icon trong `assets/` được sao chép từ bộ nguồn tại `../../assets/`. Font Be Vietnam Pro kèm OFL; giấy phép được đăng ký vào trang giấy phép app. Danh tính thương mại, asset tạo sinh và phụ thuộc cần kiểm tra trước khi phát hành.
