# Đồng bộ giai đoạn 2

## Dữ liệu và cách ly

SQLite khách giữ tên database `little_island` để bảo toàn dữ liệu giai đoạn 1. Database tài khoản tách theo backend authority và Supabase user UUID; hồ sơ, mục tiêu ngày, intake, outbox và metadata không dùng chung với tài khoản khác. Migration v1 → v2 chỉ thêm `sync_metadata`, giữ dữ liệu cũ. Khi đăng xuất, cache tài khoản ở lại nhưng app mở lại database khách; đăng nhập đúng tài khoản mới mở cache đó.

Giai đoạn 3 nâng local schema v3, thêm `pet` mặc định `cat`; backend thêm cùng trường vào profile. RPC giữ nguyên pet đã lưu nếu client cũ không gửi trường này. Tiến độ bữa ăn vẫn được tính từ lịch sử, không tách hoặc nhân đôi theo loại thú.

Supabase session và PKCE verifier lưu qua flutter_secure_storage trên Android/iOS. Không lưu token trong outbox hoặc database hydration. Web dùng storage của trình duyệt, có giới hạn bảo vệ khác nền tảng native. Android tắt autobackup để tránh khôi phục khóa mã hóa không hợp lệ. Cache hydration chưa mã hóa ở mức ứng dụng; dùng sandbox hệ điều hành. Chưa có chức năng xóa cache/tài khoản từ app.

## Giao thức

1. Thao tác người dùng ghi local và outbox cùng giao dịch; mỗi lệnh có UUID độc lập. Gửi theo thứ tự hàng SQLite, không sắp theo đồng hồ thiết bị vì thời gian có thể bị chỉnh lùi.
2. Tải hồ sơ, mục tiêu và intake, gồm tombstone, theo trang 500 dòng; tránh giới hạn API 1.000 dòng. Bản hiện tại tải toàn bộ lịch sử mỗi chu kỳ, chưa tối ưu cursor/delta cho lịch sử rất lớn.
3. Giữ dữ liệu local có lệnh đang chờ; không nâng baseline revision đã biết qua các thay đổi offline. Với dữ liệu chưa từng thấy server, lấy baseline để nhập vào profile/ngày hiện có.
4. Trước khi gọi RPC, lưu request gồm expected revision vào metadata. Mất phản hồi hoặc mở lại app sẽ gửi đúng request/command ID cũ. Server ghi mutation và receipt cùng transaction.
5. Khi nhận thành công, cập nhật revision và xóa riêng command đã xác nhận. Thay đổi phát sinh trong lúc gửi tiếp tục ở outbox.
6. Revision conflict: lấy bản server, bỏ các lệnh đang chờ của riêng entity đó và hiển thị số xung đột. Chính sách **server thắng khi xung đột**, không ghi đè âm thầm phiên bản mới hơn. Tombstone không được sống lại.
7. Tải lại dữ liệu, tính lịch nhắc local, ghi thời gian đồng bộ. Chạy khi có thay đổi, trở lại foreground, bấm đồng bộ hoặc mỗi 30 giây khi app hoạt động; request dữ liệu timeout 20 giây. Không hứa hẹn đồng bộ nền khi app đã đóng.

`apply_intake_command` xử lý intake. `apply_settings_command` xử lý profile và mục tiêu ngày, có chung receipt journal và khóa theo user. Client không được ghi trực tiếp các bảng. `user_id` luôn lấy từ JWT, không tin payload. RLS giới hạn dữ liệu được đọc. Profile dùng revision ban đầu 1; mục tiêu/intake chưa tồn tại dùng expected revision null.

Thông báo là cài đặt riêng từng thiết bị, không kéo từ server. Các lần cập nhật lịch được tuần tự hóa để tránh lịch của tài khoản cũ ghi đè tài khoản mới. Chọn một thiết bị nhắc chính trên server chưa được triển khai; hiện người dùng bật/tắt trên từng máy.

## Nhập lịch sử khách

Người dùng đăng nhập, chọn nhập và xác nhận. Trước khi nhập phải kết nối được backend. Target transaction dùng ID intake ổn định và marker hoàn thành; source journal gắn dữ liệu khách vào user đã nhận. Retry không nhân đôi. Giữ tombstone và mục tiêu ngày đã có trên server; hồ sơ khách chỉ làm hồ sơ khởi đầu khi tài khoản còn trống/chưa chỉnh profile. Bản hiện tại không xóa dữ liệu khách sau khi nhập.

## Kiểm chứng

- `flutter test`: nghiệp vụ, transaction, migration giữ dữ liệu, luồng app và bố cục.
- `scripts/backend.ps1 Test`: SQL rollback cho RLS, grant, replay, revision, constraint, tombstone.
- `scripts/test-mobile-sync.ps1`: fixture Auth + SQLite + RPC thật; mất mạng, mất phản hồi sau commit, gửi lại sau restart engine, xung đột intake/profile/goal, tombstone, nhập khách, cách ly, khôi phục >1.000 dòng và đăng xuất/đăng nhập lại. Fixture được dọn bằng admin API; service key chỉ ở môi trường tiến trình test.
- `scripts/test-mobile-android.ps1`: tài khoản fixture local, controller đăng nhập thật trong app, lưu phiên secure storage, upload, khôi phục bằng database mới và đăng xuất trên emulator. Không dùng tài khoản OAuth thật.

Giới hạn: chưa có OAuth credentials/E2E của ba provider, hợp nhất hai tài khoản có sẵn, xóa tài khoản từ app, server-authoritative pet rewards, thiết bị nhắc chính hoặc deploy VPS. Kiểm thử iOS cần macOS/Xcode.
