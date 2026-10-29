# Ghi nhận kiểm chứng giai đoạn 3

Ngày 29/10/2026. Windows, Flutter 3.47.8, Android emulator Medium Phone API 37. Không thay thế kiểm thử Android/iPhone thật.

## Đã quan sát

- Probe `closed`: lịch inexact được đặt qua cùng `ReminderService.scheduleSlots` của app; đưa app về nền và thu hồi tiến trình bằng `am kill` (fallback kill dưới UID của app nếu còn PID); xác minh không còn PID trước khi chờ; `dumpsys notification` ghi nhận notification ID 9101. Không dùng force-stop sau khi đặt lịch.
- Probe `reboot`: reboot emulator, không mở lại app, quan sát log `Restored 1 slots after android.intent.action.BOOT_COMPLETED` và alarm `RTC_WAKEUP` trỏ đến `ScheduledNotificationReceiver`. Script đã được sửa để chờ receiver sau khi boot flag chuyển sang 1.
- Đây là hai kiểm tra riêng: việc alarm được khôi phục sau reboot không tự chứng minh thông báo đã phát sau reboot. Inexact alarm có thể được OS trì hoãn.
- Probe `timezone` đã qua: đóng tiến trình app, tắt tự nhận múi giờ trên emulator trong thời gian test, đổi sang Asia/Tokyo, quan sát receiver và cache JSON lưu đúng timezone; khôi phục múi giờ/cài đặt ban đầu trong `finally`. Receiver lấy timezone từ broadcast để tránh dữ liệu cache của tiến trình.
- Widget tests: ba thú, ngưỡng tăng trưởng, phản hồi cho ăn hữu hạn; migration v1 giữ lịch sử/outbox và thêm pet mặc định. Lựa chọn pet được lưu trong hồ sơ.
- Icon App Store 1024×1024 đã kiểm tra không có alpha channel; nguồn SVG và script sinh ảnh nằm trong repo.
- Bộ offline có 19 ca passed; analyzer sạch. SQL/revision/RLS và bài đồng bộ qua Supabase local đã qua với pet=dog. Android integration test đã qua đăng nhập fixture, secure storage, upload 300 ml, khôi phục pet=fish trong database mới và đăng xuất. Fixture đã được dọn.
- Bản dự thảo quyền riêng tư/điều khoản/xóa dữ liệu có thể đọc offline. Chức năng xóa tài khoản chưa triển khai theo lựa chọn người dùng.
- Đã biên dịch AAB release qua Gradle với cờ unsigned QA, gồm AOT, native libraries, R8 và lint vital release. Artifact `.tools/android-run/little-island-UNSIGNED-QA.aab` khoảng 30 MB; `jarsigner -verify` trả `jar is unsigned`. Script kiểm tra không có entry chữ ký trong AAB và luôn bỏ signing config ở chế độ QA, kể cả khi có key.properties. Không nhúng cấu hình backend production, không ký hoặc upload store.

## Bằng chứng và lệnh tái lập

Ảnh [pets-gallery.png](pets-gallery.png) được xuất từ Flutter widget thật. Log probe nằm trong `.tools/android-run/probe-closed.log`, `probe-reboot.log` và log timezone khi hoàn tất; không commit log thiết bị thô có thể chứa thông tin vận hành.

Kiểm tra trực tiếp APK thường trên emulator: đã chọn Bubbles từ thiết lập, lưu và ghi nhận 250 ml, quan sát cá ăn và tiến độ 13%; [ảnh Bubbles](android-bubbles-phase3.png), [ảnh splash](android-splash-phase3.png). Trang quyền riêng tư mở được từ tài liệu đóng gói offline. Hồ sơ trên emulator là dữ liệu thử.

Sau các sửa vị trí cuộn/lựa chọn form và snackbar, analyzer cùng 19 ca offline tiếp tục passed. Đã tạo lại AAB unsigned, web release và APK debug bằng Flutter CLI; helper QA dùng `--android-project-arg=allowUnsignedRelease=true` để tạo registrant release đúng, không dùng registrant debug chứa integration_test. APK cuối đã cài và mở lại trên emulator; [ảnh bản cuối](android-phase3-final.png). Preview localhost:5174 trả HTTP 200.

```powershell
./scripts/test-android-reminders.ps1 -Mode closed
./scripts/test-android-reminders.ps1 -Mode reboot
./scripts/test-android-reminders.ps1 -Mode timezone
./scripts/test-mobile-sync.ps1
./scripts/test-mobile-android.ps1
```

Probe thay entrypoint debug; luôn build/cài lại app thường sau khi chạy. Dùng emulator có dữ liệu thử. Không hứa nhận nhắc khi người dùng force-stop hoặc khi bị OS/nhà sản xuất hạn chế hoạt động.

## Chưa kiểm chứng

Thiết bị Android thật, iOS trên macOS/iPhone, Doze/battery saver dài hạn và giới hạn riêng của OEM, DST trên thiết bị thật, OAuth thật, production server/signing/store. Xem [checklist phát hành](../release-checklist.md).
