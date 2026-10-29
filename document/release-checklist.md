# Chuẩn bị phát hành giai đoạn 3

Cập nhật 29/10/2026. Đây là bộ chuẩn bị kỹ thuật và nghiệm thu, không phải xác nhận app đã sẵn sàng lên store. Người dùng chọn **chỉ chuẩn bị tài liệu xóa tài khoản**, chưa triển khai chức năng đó. Không có tài khoản store/server mới được tạo, không xuất bản hoặc mua dịch vụ.

## Phạm vi đã chuẩn bị

- Mèo Mochi, chó Biscuit và cá Bubbles; chọn trong Cá nhân, lưu SQLite và đồng bộ profile. Các bạn dùng chung tiến độ bữa ăn từ lịch sử, không yêu cầu uống thêm khi đổi thú.
- Ba giai đoạn: Lv. 1–2 bé nhỏ, Lv. 3–5 đang lớn, Lv. 6+ trưởng thành; phản hồi chạm/cho ăn có hoạt ảnh hữu hạn và tôn trọng giảm chuyển động.
- Icon gốc SVG giọt nước/đảo nhỏ, PNG Android/iOS/web, adaptive icon và splash Android 12+, splash iOS.
- Trang quyền riêng tư, điều khoản, thông tin xóa dữ liệu đọc offline; đều thể hiện trạng thái bản thử nghiệm/dự thảo.
- Release Android không còn dùng khóa debug khi thiếu khóa thật. File `android/key.properties.example` và `release-config.example.json` không chứa secret thật.

## Định danh và khóa do chủ dự án cung cấp

- Chốt tên thương mại: hiện native display name Little Island, giao diện có wordmark mizu. Chưa đổi tên thương mại ngoài các thiết kế đã có.
- Chốt application ID Android và bundle ID iOS trước khi đăng ký store/OAuth; hiện vẫn là định danh phát triển. Đồng bộ URI callback theo [OAuth setup](oauth-setup.md).
- Chủ dự án giữ upload keystore, alias, mật khẩu và bản sao lưu an toàn. Không gửi các giá trị đó trong chat hoặc commit `key.properties`/keystore. Không tự tạo khóa phát hành thay chủ dự án.
- Apple Developer team, signing/provisioning và quyền truy cập Play Console/App Store Connect chưa có trong phiên này.

## Android

1. Chạy `flutter analyze`, `flutter test`, SQL/backend sync checks và emulator tests.
2. Kiểm tra máy thật: khung nhỏ/lớn, text scale 1.0/1.5/2.0, portrait/fullscreen, vùng trạng thái, nút back, offline và quyền thông báo bị từ chối.
3. Kiểm tra nhận thông báo khi app ở nền/tiến trình bị dừng bình thường, reboot và đổi múi giờ. Force-stop của hệ điều hành là tình huống riêng; không hứa app tiếp tục nhắc khi bị force-stop.
4. Với APK probe dùng `scripts/test-android-reminders.ps1 -Mode closed|reboot|timezone`, chỉ chạy trên emulator có dữ liệu thử. Probe thay entrypoint và cấp quyền thông báo cho app debug; cài lại app thường bằng `scripts/run-mobile.ps1` sau kiểm thử.
5. Receiver khôi phục dùng adapter cache của `flutter_local_notifications` **22.3.3 đã pin**. Nâng plugin phải kiểm tra lại cache schema, reboot, đổi giờ và thông báo thật; không tự bỏ pin.
6. Lịch inexact không bảo đảm đúng phút. Android có thể batch/trì hoãn; xem [tài liệu alarm chính thức](https://developer.android.com/develop/background-work/services/alarms). Mở app để tính lại lịch theo lượng nước còn lại; offline notification không đồng nghĩa background sync.

Build debug cho emulator bằng `scripts/run-mobile.ps1 -BuildOnly -LocalAuth`. Bản debug x86_64 không phải bản phân phối ARM64.

Build release cần sao chép hai file example và điền giá trị thật tại máy chủ dự án. Kiểm tra các phần còn thiếu:

```powershell
./scripts/build-release.ps1 -ValidateOnly
```

Script chủ động báo các phần chưa hoàn thành trong phạm vi hiện tại. Nó chưa mở khóa build phát hành chỉ bằng cách điền credentials. Có thể biên dịch AAB **unsigned cho QA** với Gradle property `allowUnsignedRelease=true`; artifact này không được coi là bản phát hành/ký/store-ready.

Lệnh kiểm tra AOT/native compilation độc lập: `./scripts/build-unsigned-qa.ps1`. Nó tạo `.tools/android-run/little-island-UNSIGNED-QA.aab` không ký và không nhúng cấu hình production. Không dùng artifact này để phát hành hoặc làm bằng chứng đã kiểm thử backend production.

## iOS trên macOS/Xcode

1. Cài Flutter tương thích, Xcode/CLI tools và CocoaPods nếu project yêu cầu; `flutter doctor -v`.
2. `flutter pub get`; mở `ios/Runner.xcworkspace`, chọn team/bundle ID chính thức, kiểm tra provisioning và `Runner.entitlements` cho Keychain.
3. Kiểm tra AppIcon (PNG không alpha), LaunchScreen, URL scheme, callback PKCE và AppDelegate notification delegate. Không có quyền HealthKit, camera, vị trí hoặc tracking được thêm.
4. Kiểm tra privacy manifests/required-reason APIs của app và dependency trong archive thực tế. Không khai báo reason code giả để qua bước tải lên.
5. Chạy `flutter test`, `flutter build ios --debug --no-codesign` trên macOS rồi simulator/iPhone thật; tiếp tục archive/IPA với signing thật khi các điều kiện phát hành hoàn tất.
6. iPhone thật: permission lần đầu/từ chối, thông báo khi đóng app/reboot, đổi múi giờ và DST, hạn pending requests, callback đăng nhập khi app đóng, session Keychain và đổi tài khoản.
7. Xcode Validate App, export compliance, deployment target và TestFlight chỉ sau khi chủ dự án xác nhận tài khoản/cấu hình. Windows không kiểm chứng được các bước này.

## Chính sách và store

- Điền chủ thể vận hành, email hỗ trợ, domain công khai, nơi lưu dữ liệu, nhà xử lý, thời hạn log/backup và quy trình quyền người dùng trong bản chính sách cuối cùng. Tài liệu trong app hiện là dự thảo cho bản thử nghiệm.
- Đưa privacy/terms/deletion lên URL HTTPS công khai rồi kiểm tra nội dung khớp hành vi app. Chưa có website hỗ trợ/xóa tài khoản được triển khai.
- **Chưa đủ điều kiện account deletion**: Apple yêu cầu app hỗ trợ tạo tài khoản phải cho xóa tài khoản trong app; Google Play cũng có yêu cầu xóa tài khoản và tài nguyên web liên quan. Chỉ có tài liệu không đáp ứng việc này. Xem [Apple](https://developer.apple.com/support/offering-account-deletion-in-your-app/), [Google Play](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en).
- Khai App Privacy/Data Safety theo hành vi thực tế: tài khoản/email/user ID, profile, mục tiêu và lịch sử uống nước đồng bộ. Không khai “không thu thập dữ liệu” cho bản có sync. Kiểm tra phân loại dữ liệu sức khỏe/thể chất và log IP của hạ tầng. Tham khảo [Apple App Privacy](https://developer.apple.com/app-store/app-privacy-details/), [Google User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en).
- Hoàn tất tài khoản tester, OAuth consent/provider review, ảnh store từ build thật, mô tả tính năng đúng, content-rating questionnaire và hướng dẫn reviewer. Không công bố HealthKit/Health Connect hoặc công thức cá nhân hóa khi chưa có.
- Kiểm tra giấy phép dependency, font OFL, tài nguyên tạo sinh có sẵn và nhận diện thương mại của publisher. Icon mới là vector gốc trong repository; quy trình sinh ảnh tại `scripts/generate-branding.cjs` dùng sharp.

## Các điều kiện chưa có

OAuth credentials, server production/domain/backup, signing và tài khoản store, iPhone/macOS, thiết bị Android thật, tính năng xóa tài khoản và nghiệm thu chính sách phát hành. Những phần này không được đánh dấu đã hoàn thành bằng kiểm thử emulator hoặc bản build unsigned.
