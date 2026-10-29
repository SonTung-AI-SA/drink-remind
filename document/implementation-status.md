# Tiến độ triển khai

Cập nhật: 29/10/2026. Phương án sản phẩm/kiến trúc đã được người dùng chấp thuận để bắt đầu. Backend đã chốt **Supabase tự triển khai trên server riêng**. Phạm vi tích hợp giai đoạn 2 được người dùng chốt; hiện triển khai và kiểm chứng trên Supabase local.

## Giai đoạn 1 — App local

- Project Flutter có Android, iOS và web phục vụ kiểm tra từ cùng mã nguồn.
- Riverpod quản lý nguồn dữ liệu; Drift/SQLite lưu hồ sơ, mục tiêu ngày, lần uống, lịch nhắc và outbox trong giao dịch.
- Giao diện Đảo nhỏ với tài nguyên PNG/atlas thật, font tiếng Việt lưu offline, ba nút chỉ có icon.
- Thiết lập hồ sơ và mục tiêu nhập tay; chưa dùng công thức gợi ý cá nhân hóa.
- Ghi nhận nước, dung tích tùy chọn, sửa/xóa/hoàn tác, lịch sử tuần và mục tiêu ngày.
- Thú Mochi phản hồi; quy tắc local cho bữa ăn tăng cấp: ít nhất 100 ml, cách nhau ít nhất 30 phút, tối đa 8/ngày và không tăng sau khi đã đạt mục tiêu. Mọi lần ghi nhận vẫn có phản hồi vui. 5 bữa tăng một cấp.
- Lịch không dịch chuyển khi chỉ mở lại màn hình. Tính lại sau thay đổi; tối đa 350 ml/mốc, không ép uống bù cuối ngày.
- Cấu hình thông báo Android/iOS, rolling horizon tối đa 56 mốc; không xin quyền exact alarm. Android dùng lịch inexact, có thể trễ do hệ điều hành.

## Giai đoạn 2 — Tài khoản và đồng bộ local đã triển khai; OAuth chờ credentials

- Đã chạy Supabase local bằng CLI 2.122.0/Docker: PostgreSQL, Auth, REST, Studio và Mailpit. API cổng 15421, database 15422, Studio 15423, Mailpit 15424; tránh dải cổng Windows dành riêng.
- Đã áp dụng migration `202610280001_hydration.sql`: profiles, daily_goals, water_intakes, sync_receipts; RLS theo tài khoản.
- Đã có RPC ghi/sửa/xóa intake với command idempotency, revision conflict và tombstone.
- Đã qua kiểm thử SQL rollback và HTTP Auth/signup/profile/RPC/retry; tài khoản synthetic được xóa sau kiểm tra.
- Đã nối SDK Supabase vào app qua public config; Android emulator dùng `10.0.2.2:15421`. Token/PKCE native lưu bằng secure storage.
- Có UI Google/Apple/Facebook, callback PKCE Android/iOS và liên kết identity. Ba nhà cung cấp chưa bật vì chưa có credentials; chưa kiểm chứng OAuth thật. Người dùng đã yêu cầu chuẩn bị [hướng dẫn cấu hình](oauth-setup.md).
- Database riêng theo tài khoản/backend; đăng xuất trở về khách, giữ cache riêng để gửi tiếp khi đúng tài khoản đăng nhập lại.
- Đã có outbox idempotent, lưu request trước HTTP, revision cho intake/profile/goal, server thắng khi xung đột, tombstone và phân trang khôi phục toàn bộ lịch sử.
- Nhập dữ liệu khách có xác nhận, chống trùng và gắn nguồn khách vào một tài khoản. Liên kết identity không tự hợp nhất hai tài khoản đã tồn tại.
- Đã kiểm thử offline, mất phản hồi sau server commit, replay, conflict intake/profile/goal, tombstone, RLS, nhập khách và khôi phục hơn 1.000 bản ghi qua backend thật. Android integration test đã qua đăng nhập fixture, secure storage, upload, khôi phục và đăng xuất; fixture đã dọn.
- Còn: production VPS (ngoài phạm vi lượt này), credentials/E2E OAuth, hợp nhất hai tài khoản đã có, server xác nhận phần thưởng, xóa tài khoản từ app và thiết bị nhận nhắc chính. Xem [giao thức và giới hạn](sync-protocol.md).

## Giai đoạn 3 — Hoàn thiện và chuẩn bị phát hành

- Đã thêm chó Biscuit/cá Bubbles bằng vector, mèo Mochi giữ atlas; chọn thú trong Cá nhân và đồng bộ qua profile. Ba giai đoạn ở Lv. 1/3/6, phản hồi chạm/cho ăn hữu hạn, tôn trọng giảm chuyển động. [Ảnh QA](qa/pets-gallery.png).
- Local schema v3 thêm pet; backend migration `202610290002_pet_preferences.sql` giữ tương thích client cũ.
- Icon SVG gốc, PNG Android/iOS/web, adaptive icon/themed icon, splash Android/iOS và màn hình chờ có nhận diện. Icon iOS 1024 đã kiểm tra không có alpha.
- Đã kiểm tra thông báo sau khi app bị thu hồi tiến trình (xác minh hết PID), khôi phục pending alarm sau reboot và đổi múi giờ khi app đóng trên API 37. Đã sửa receiver dùng timezone từ broadcast và kiểm tra cache lưu đúng timezone. Lịch vẫn inexact, không bảo đảm đúng phút. Chi tiết [bằng chứng QA](qa/phase3-validation.md).
- Có trang quyền riêng tư/điều khoản/thông tin xóa dữ liệu offline và [kế hoạch xóa tài khoản](account-deletion-plan.md). Người dùng chọn **chỉ chuẩn bị tài liệu**, chưa thêm chức năng xóa tài khoản; đây là điều kiện phải hoàn tất trước phát hành app có tài khoản.
- Đã bỏ release signing bằng khóa debug, thêm cấu hình example, kiểm tra điều kiện phát hành và script AAB unsigned cho QA. Giới hạn Gradle worker/bộ nhớ để tránh quá tải máy phát triển.
- AAB unsigned QA đã build thành công qua AOT/R8/lint release; xác minh không có chữ ký. Không coi artifact đó là bản đã ký, đã kiểm thử trên ARM64 thật hoặc đã sẵn sàng phát hành.
- [Checklist phát hành](release-checklist.md) bao gồm định danh, OAuth, chính sách và macOS/Xcode. Còn signing/tài khoản store, server production, credentials OAuth, Android/iPhone thật, macOS và nghiệm thu chính sách của publisher. Chưa xuất bản app hoặc triển khai server production.

## Giới hạn minh bạch

Khi chưa đăng nhập, app giữ dữ liệu khách trên thiết bị. Khi có phiên tài khoản, app đồng bộ thật với backend đã cấu hình và khôi phục được lịch sử. Hiện backend là local trên máy phát triển, chưa phải dịch vụ production để dùng từ Internet. OAuth chờ cấu hình; tài khoản email local chỉ phục vụ kiểm thử debug. Bản web không hỗ trợ nhắc nền như mobile. Đồng bộ chạy khi app hoạt động, không cam kết chạy nền sau khi app đóng.

Khung 390 × 844 là tham chiếu. App dùng bố cục thích ứng, cỡ chữ nội dung 16/phụ 14, có cuộn khi cần và thanh điều hướng riêng. Cài đặt fullscreen phụ thuộc giới hạn phiên bản hệ điều hành; không che vùng thao tác bắt buộc do OS áp đặt.

## Kiểm tra

Đã chạy thành công **19 ca kiểm thử offline** (bài tích hợp backend được skip trong bộ offline và chạy riêng), gồm migration, thú nuôi/hoạt ảnh và thứ tự outbox khi đồng hồ bị chỉnh lùi; `flutter analyze`: **không có lỗi/cảnh báo**. SQL checks và `scripts/test-mobile-sync.ps1` đã qua, có kiểm tra đồng bộ lựa chọn thú; Android integration test bản giai đoạn 3 đã qua trên API 37 với đăng nhập fixture, secure storage, upload, khôi phục nước/lựa chọn cá và đăng xuất. Bố cục kiểm tra ở 360×800, 390×844 và 414×896 đều giữ nút ghi nhận trong màn hình đầu tiên.

Bản Android debug thường đã build/cài lại sau kiểm thử; `flutter build web --release` với cấu hình Supabase local cũng thành công. Các fixture `sync-*`/`android-sync-*` đã được dọn (xác nhận số tài khoản còn lại bằng 0). Dữ liệu trên giả lập là dữ liệu thử; không dùng bộ integration test trên thiết bị có dữ liệu cần giữ.

Ảnh render Flutter thật: [island-390x844.png](qa/island-390x844.png). Bản web được phục vụ bằng `node scripts/preview-mobile.cjs` tại localhost:5174; HTTP HTML và SQLite WASM đã được kiểm tra trả 200, MIME WASM đúng.

Các lệnh chạy ở `apps/mobile/README.md`. APK debug Android đã build và chạy trên giả lập; chưa build IPA hoặc kiểm thử thông báo trên máy thật. Android tắt Kotlin incremental compilation để tránh lỗi đường dẫn khác ổ đĩa giữa Pub cache ở C và project ở D.

Backend local: [hướng dẫn](../supabase/README.md), `scripts/backend.ps1 Start|Stop|Status|Migrate|Test`. Kiểm tra HTTP bằng `scripts/test-backend-http.ps1`. Các container dự án khác không bị thay đổi.
