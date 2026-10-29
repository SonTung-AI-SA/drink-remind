# Mizu

## App Flutter đang phát triển

Mã app iOS/Android hiện nằm trong [`apps/mobile`](apps/mobile/README.md), dùng Flutter + Riverpod + Drift/SQLite. Đã có luồng tài khoản và đồng bộ Supabase local; Google/Apple/Facebook chờ cấu hình credentials. Android đã chạy trên giả lập API 37.

Giai đoạn 3 đã bổ sung chó/cá, ba giai đoạn tăng trưởng, icon/splash và tài liệu offline. Kiểm chứng thông báo khi app bị thu hồi tiến trình, khôi phục sau reboot/đổi múi giờ trên emulator; xem [bằng chứng QA](document/qa/phase3-validation.md) và [checklist phát hành](document/release-checklist.md). Chưa phát hành store; xóa tài khoản chỉ có tài liệu theo phạm vi đã chốt.

```powershell
./scripts/flutter.ps1 test
./scripts/flutter.ps1 run -d chrome
```

Bản web release để xem thử:

```powershell
./scripts/flutter.ps1 build web --release
node scripts/preview-mobile.cjs
```

Mở http://localhost:5174. Không mở file build bằng file:// vì SQLite worker/WebAssembly cần HTTP. Bản web không có nhắc nền mobile.

Xem [tiến độ và phần còn lại](document/implementation-status.md), [kiến trúc](document/architecture.md) và [cấu hình server đề xuất](infra/self-host/README.md).

## Backend local

Supabase local đã chạy trên Docker, tách riêng khỏi web Flutter:

- API/Auth/REST: http://127.0.0.1:15421
- Studio: http://127.0.0.1:15423
- Email kiểm thử: http://127.0.0.1:15424
- PostgreSQL: cổng 15422.

```powershell
./scripts/backend.ps1 Start
./scripts/backend.ps1 Status
./scripts/backend.ps1 Test
./scripts/test-backend-http.ps1
./scripts/backend.ps1 Stop
```

Xem [hướng dẫn backend](supabase/README.md). Chạy app nối server local bằng `./scripts/run-mobile.ps1`; [giao thức đồng bộ](document/sync-protocol.md), [cấu hình OAuth](document/oauth-setup.md). Không chia sẻ `.tools/supabase/status.json` vì có khóa quản trị local.

## Bản thử nghiệm web cũ

Nội dung dưới đây mô tả bản HTML cũ ở thư mục gốc, được giữ lại làm tham khảo, không phải app Flutter hiện tại. Quy tắc mục tiêu/phần thưởng trong prototype không được dùng thay cho bản triển khai mới.

Ứng dụng web nhắc uống nước tiếng Việt, chạy bằng HTML/CSS/JavaScript thuần, không cần cài thư viện.

## Chạy

```sh
node server.js
```

Mở http://localhost:5173. Dữ liệu lưu trong localStorage của trình duyệt hiện tại.

## Chức năng

- Mục tiêu nhập tay hoặc ước tính khởi đầu theo cân nặng; lưu hồ sơ giới tính, tuổi, chiều cao.
- Chia lượng nước còn lại thành tối đa 8 mốc trong khung giờ đã chọn, tự tính lại khi ghi nhận nước hoặc đổi dung tích/mục tiêu.
- Ghi nhận dung tích, giờ uống, hoàn tác từng lần; lịch sử 7 ngày và chuỗi ngày đạt mục tiêu.
- Mèo Mochi, chó Bơ, cá Bong Bóng; mỗi lần uống là một bữa ăn, 5 bữa tăng một cấp; lưu tiến độ từng thú.
- Thông báo trình duyệt khi app đang mở và được cấp quyền. Không có nhắc nền khi đóng trang.
- Giao diện thích ứng điện thoại, máy tính; ngày mới tự bắt đầu lại, lịch sử vẫn giữ.

## Phạm vi

Đây là bản đầu tiên chạy trên một thiết bị. Chưa có tài khoản, đồng bộ, push nền hoặc ứng dụng native. Ước tính 30 ml/kg là quy tắc đơn giản để khởi tạo mục tiêu, không phải công thức y khoa cá nhân hóa; tuổi/giới tính/chiều cao chưa tham gia công thức. Mọi lần uống đều cho thú ăn; các lần trong khoảng 15 phút trước mốc tiếp theo được đánh dấu đúng nhịp. Hệ thống không thúc ép uống bù khi hết giờ.
