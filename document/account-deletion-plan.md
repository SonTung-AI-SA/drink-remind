# Quy trình xóa tài khoản — tài liệu chuẩn bị

Trạng thái: **chưa triển khai**, theo lựa chọn của người dùng ngày 29/10/2026. Không có nút xóa tài khoản hoặc endpoint tự phục vụ được thêm trong giai đoạn này.

## Hành vi cần có khi được duyệt triển khai

1. Mục xóa tài khoản dễ tìm trong app và trang web yêu cầu xóa có URL công khai.
2. Hiển thị dữ liệu sẽ mất: hồ sơ, mục tiêu, lịch sử, tiến độ thú, phiên đăng nhập; nói rõ pending offline sẽ bị bỏ và hành động không thể hoàn tác.
3. Xác nhận chủ tài khoản; với yêu cầu từ web phải xác minh quyền sở hữu, không xóa theo email tùy ý.
4. Server lấy user ID từ phiên xác thực, không tin user ID của client. Xử lý idempotent, xác nhận kết quả thực sự khi mạng mất phản hồi, bảo đảm không xóa tài khoản khác.
5. Thu hồi session và liên kết/token nhà cung cấp khi có yêu cầu áp dụng, gồm xử lý Sign in with Apple. Không nhúng provider secret hoặc service-role vào app.
6. Xóa/cascade dữ liệu hoạt động và đánh dấu ngăn thiết bị cũ đẩy dữ liệu sống lại; dọn cache của tài khoản trên thiết bị sau khi server xác nhận, không xóa nhầm cache của người khác.
7. Công bố cách xử lý backup, tombstone và log, dữ liệu phải giữ nếu có cơ sở phù hợp và thời hạn cụ thể. Không hứa “xóa ngay mọi bản sao” khi hạ tầng chưa làm được.
8. Test retry, offline, token hết hạn, hai thiết bị, account đã xóa, sai tài khoản, provider revocation lỗi và dọn dữ liệu liên quan.

## Vận hành thử nghiệm hiện tại

Tài khoản fixture của các script kiểm thử được tạo và xóa bởi admin API local trong `finally`. Đây không phải luồng tự phục vụ cho người dùng thật. Không dùng service-role trong frontend hoặc gửi key cho người dùng để tự xóa.

Chưa có email/domain hỗ trợ chính thức để tiếp nhận yêu cầu. Khi chủ dự án cung cấp đầu mối, cần hoàn thiện quy trình và cập nhật chính sách/app trước khi đưa dịch vụ tài khoản vào sử dụng công khai.

Nguồn tham chiếu: [Apple account deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app/), [Google Play account deletion](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en). Tài liệu này là đặc tả sản phẩm/kỹ thuật; đơn vị vận hành phải duyệt chính sách áp dụng trước phát hành.
